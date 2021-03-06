# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Api::ProjectsController do
  render_views
  let(:user) { create(:user) }
  let(:admin) { create(:admin) }
  let(:manager) { create(:manager) }
  let(:project_name) { SecureRandom.hex }

  def full_project_response(project)
    project.attributes.slice('id', 'name', 'work_times_allows_task', 'color', 'active', 'leader_id')
  end

  describe '#index' do
    it 'authenticates user' do
      get :index, format: :json
      expect(response.code).to eql('401')
    end

    it 'returns projects' do
      sign_in(user)
      project = create(:project)
      FactoryGirl.create :work_time, project: project, user: user, starts_at: Time.current - 40.minutes, ends_at: Time.current - 30.minutes
      project_rate = ProjectRateQuery.new(active: true).results.first
      get :index, format: :json

      expected_json = [
        {
          color: project_rate.color,
          name: project_rate.name,
          project_id: project_rate.project_id,
          user: {
            name: "#{project_rate.user_first_name} #{project_rate.user_last_name}"
          }
        }
      ].to_json

      expect(response.code).to eql('200')
      expect(response.body).to be_json_eql(expected_json)
    end

    it 'filters by active' do
      sign_in(user)
      active_project = create(:project)

      FactoryGirl.create :work_time, project: active_project, user: user, starts_at: Time.current - 40.minutes, ends_at: Time.current - 30.minutes

      active_project_rate = ProjectRateQuery.new(active: true).results.first

      expected_active_json = [
        {
          color: active_project_rate.color,
          name: active_project_rate.name,
          project_id: active_project_rate.project_id,
          user: {
            name: "#{active_project_rate.user_first_name} #{active_project_rate.user_last_name}"
          }
        }
      ].to_json

      get :index, format: :json

      expect(response.code).to eql('200')
      expect(response.body).to be_json_eql(expected_active_json)
    end

    it 'hides internal projects' do
      sign_in(user)
      internal_project = create(:project, internal: true)

      FactoryGirl.create :work_time, project: internal_project, starts_at: Time.current - 40.minutes, ends_at: Time.current - 30.minutes, user: user

      get :index, format: :json

      expect(response.code).to eql('200')
      expect(response.body).to be_json_eql([].to_json)
    end
  end

  describe 'list' do
    it 'correctly display active projects' do
      sign_in user
      project = FactoryGirl.create :project
      FactoryGirl.create :project, active: false

      expected_json = [
        {
          id: project.id,
          name: project.name,
          color: project.color,
          active: project.active,
          leader_id: project.leader_id
        }
      ].to_json

      get :list, format: :json

      expect(response.body).to eq(expected_json)
    end

    it 'correctly display all projects' do
      sign_in user
      project = FactoryGirl.create :project
      inactive_project = FactoryGirl.create :project, active: false

      expected_json = [
        {
          id: project.id,
          name: project.name,
          color: project.color,
          active: project.active,
          leader_id: project.leader_id
        },
        {
          id: inactive_project.id,
          name: inactive_project.name,
          color: inactive_project.color,
          active: inactive_project.active,
          leader_id: inactive_project.leader_id
        }
      ].to_json

      get :list, params: { display: 'all' }, format: :json

      expect(response.body).to eq(expected_json)
    end

    describe 'filters' do
      context 'all' do
        it 'return all possible records' do
          sign_in admin
          FactoryGirl.create :project, active: false
          FactoryGirl.create :project, active: true

          get :list, params: { display: 'all' }, format: :json

          expected_json = Project.all.map do |project|
            {
              id: project.id,
              name: project.name,
              color: project.color,
              active: project.active,
              leader_id: project.leader_id
            }
          end.to_json

          expect(response.body).to eq expected_json
        end
      end

      context 'active' do
        it 'return all possible records' do
          sign_in admin
          FactoryGirl.create :project, active: false
          FactoryGirl.create :project, active: true

          get :list, params: { display: 'active' }, format: :json

          expected_json = Project.where(active: true).map do |project|
            {
              id: project.id,
              name: project.name,
              color: project.color,
              active: project.active,
              leader_id: project.leader_id
            }
          end.to_json

          expect(response.body).to eq expected_json
        end
      end

      context 'inactive' do
        it 'return all possible records' do
          sign_in admin
          FactoryGirl.create :project, active: false
          FactoryGirl.create :project, active: true

          get :list, params: { display: 'inactive' }, format: :json

          expected_json = Project.where(active: false).map do |project|
            {
              id: project.id,
              name: project.name,
              color: project.color,
              active: project.active,
              leader_id: project.leader_id
            }
          end.to_json

          expect(response.body).to eq expected_json
        end
      end
    end
  end

  describe '#simple' do
    def project_response(project)
      project.attributes.slice('id', 'name', 'active', 'internal', 'work_times_allows_task', 'color', 'autofill', 'lunch', 'count_duration')
    end

    it 'authenticates user' do
      get :simple, format: :json
      expect(response.code).to eql('401')
    end

    it 'returns only basic project information' do
      sign_in(user)
      project = create(:project)
      get :simple, format: :json
      expect(response.code).to eql('200')
      expect(response.body).to be_json_eql([project_response(project)].to_json)
    end
  end

  describe '#show' do
    it 'authenticates user' do
      get :show, params: { id: 1 }, format: :json
      expect(response.code).to eql('401')
    end

    it 'returns info for leader' do
      sign_in user
      project = FactoryGirl.create :project, leader_id: user.id

      get :show, params: { id: project.id }

      expected_json = {
        id: project.id,
        name: project.name,
        work_times_allows_task: project.work_times_allows_task,
        color: project.color,
        active: project.active,
        leader_id: project.leader_id,
        leader: {
          id: user.id,
          first_name: user.first_name,
          last_name: user.last_name,
          email: user.email
        }
      }.to_json

      expect(response.code).to eq '200'
      expect(response.body).to eq expected_json
    end

    it 'returns info for admin' do
      sign_in FactoryGirl.create :user, admin: true
      project = FactoryGirl.create :project

      get :show, params: { id: project.id }

      expected_json = {
        id: project.id,
        name: project.name,
        work_times_allows_task: project.work_times_allows_task,
        color: project.color,
        active: project.active,
        leader_id: project.leader_id
      }.to_json

      expect(response.code).to eq '200'
      expect(response.body).to eq expected_json
    end

    it 'returns info for manager' do
      sign_in FactoryGirl.create :user, manager: true
      project = FactoryGirl.create :project

      get :show, params: { id: project.id }

      expected_json = {
        id: project.id,
        name: project.name,
        work_times_allows_task: project.work_times_allows_task,
        color: project.color,
        active: project.active,
        leader_id: project.leader_id
      }.to_json

      expect(response.code).to eq '200'
      expect(response.body).to eq expected_json
    end

    it 'returns unauth status for user' do
      sign_in FactoryGirl.create :user
      project = FactoryGirl.create :project

      get :show, params: { id: project.id }

      expect(response.code).to eq '403'
      expect(response.body).to eq('')
    end
  end

  describe '#create' do
    it 'authenticates user' do
      post :create, format: :json
      expect(response.code).to eql('401')
    end

    it 'authorizes admin or manager' do
      sign_in(user)
      post :create, format: :json
      expect(response.code).to eql('403')
    end

    it 'creates project as admin' do
      sign_in(admin)
      post :create, params: { project: { name: project_name } }, format: :json
      expect(response.code).to eql('200')
      project = Project.find_by name: project_name
      expect(response.body).to be_json_eql(full_project_response(project).to_json)
    end

    it 'creates project as manager' do
      sign_in(manager)
      post :create, params: { project: { name: project_name } }, format: :json
      expect(response.code).to eql('200')
      project = Project.find_by name: project_name
      expect(response.body).to be_json_eql(full_project_response(project).to_json)
    end
  end

  describe '#update' do
    it 'authenticates user' do
      put :update, params: { id: 1 }, format: :json
      expect(response.code).to eql('401')
    end

    it 'authorizes admin or manager' do
      sign_in(user)
      put :update, params: { id: 1 }, format: :json
      expect(response.code).to eql('403')
    end

    it 'updates project as leader' do
      sign_in user
      project = FactoryGirl.create :project, leader_id: user.id

      put :update, params: { id: project.id, project: { name: 'test', color: '#5e5e5e' } }, format: :json

      project.reload

      expect(project.name).not_to eq 'test'
      expect(project.color).to eq '#5e5e5e'
    end

    it 'creates project as admin' do
      sign_in(admin)
      project = create(:project)
      put :update, params: { id: project.id, project: { name: project_name } }, format: :json
      expect(response.code).to eql('204')
      expect(project.reload.name).to eql(project_name)
      expect(response.body).to eq('')
    end

    it 'creates project as manager' do
      sign_in(manager)
      project = create(:project)
      put :update, params: { id: project.id, project: { name: project_name } }, format: :json
      expect(response.code).to eql('204')
      expect(project.reload.name).to eql(project_name)
      expect(response.body).to eq('')
    end
  end
end
