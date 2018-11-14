import React from 'react';
import ReactDOM from 'react-dom';
import PropTypes from 'prop-types';
import moment from 'moment';
import ProjectsDropdown from './projects_dropdown.js';
import DatePicker from 'react-datepicker';
import ErrorTooltip from './errors/error_tooltip.js';
import * as Api from '../../shared/api.js';
import * as Validations from '../../shared/validations.js';

class Entry extends React.Component {
  constructor (props) {
    super(props);

    this.onChange = this.onChange.bind(this);
    this.onDateChange = this.onDateChange.bind(this);
    this.onSubmit = this.onSubmit.bind(this);
    this.recountTime = this.recountTime.bind(this);
    this.updateProject = this.updateProject.bind(this);
    this.validate = this.validate.bind(this);
    this.removeErrorsFor = this.removeErrorsFor.bind(this);
    this.paste = this.paste.bind(this);
  }

  static propTypes = {
    body: PropTypes.string,
    duration: PropTypes.number,
    task: PropTypes.string,
    project: PropTypes.object,
    starts_at: PropTypes.string,
    ends_at: PropTypes.string
  }

  state = {
    body: undefined,
    duration: 0,
    task: '',
    project: {},
    starts_at: moment().format('HH:mm'),
    ends_at: moment().format('HH:mm'),
    durationHours: '00:00',
    date: moment().format('DD/MM/YYYY'),
    errors: []
  }

  onChange (e) {
    let name = e.target.name;

    this.setState({
      [name]: e.target.value
    }, () => { this.removeErrorsFor(name); })
  }

  onDateChange (e) {
    this.setState({
      date: e.format('DD/MM/YYYY')
    }, () => { this.removeErrorsFor('date'); })
  }

  paste (object) {
    this.setState({
      body: object.body,
      project: object.project,
      project_id: object.project.id,
      task: object.task
    }, () => {
      this.projectsDropdown.assignProject(object.project);
    })
  }

  removeErrorsFor (name) {
    let errors = this.state.errors;
    delete errors[name];
    this.setState({ errors: errors });
  }

  validate () {
    const project = this.state.project;

    if (project.lunch || project.autofill) {
      return []
    } else {
      let errors = {
        body: Validations.presence(this.state.body),
        starts_at: Validations.presence(this.state.starts_at),
        ends_at: Validations.presence(this.state.ends_at),
        project_id: Validations.presence(this.state.project_id),
        duration: Validations.greaterThan(0, this.state.duration)
      }
      Object.keys(errors).forEach((key) => { if (errors[key] === undefined) { delete errors[key] } })
      return errors;
    }
  }

  onSubmit () {
    let errors = this.validate();
    let userId = URI(window.location.href).search(true)['user_id'] || currentUser.id;

    if (!_.isEmpty(errors)) {
      this.setState({ errors: errors })
    } else {
      const { body, task, project, date, starts_at, ends_at } = this.state;

      let entryData = {
        user_id: userId,
        body: body,
        task: task,
        project_id: project.id,
        starts_at: moment(`${date} ${starts_at}`, 'DD/MM/YYYY HH:mm'),
        ends_at: moment(`${date} ${ends_at}`, 'DD/MM/YYYY HH:mm')
      }

      Api.makePostRequest({
        url: '/api/work_times',
        body: { work_time: entryData }
      }).then((response) => {
        switch (parseInt(response.status)) {
          case 200:
            this.props.pushEntry(response.data);
            this.setState({
              starts_at: this.state.ends_at,
              duration: 0,
              durationHours: '00:00',
              body: '',
              task: ''
            })
            break;
          case 422:
            alert('There was an error while trying to add work time');
            break;
          default:
            alert('Internal server error');
        }
      })
    }
  }

  updateProject (project) {
    let autoSettings = {};

    if (project.lunch) {
      autoSettings = {
        ends_at: this.formattedHoursAndMinutes(moment(this.state.starts_at, 'HH:mm').add('30', 'minutes'))
      }
    } else if (project.autofill) {
      autoSettings = {
        starts_at: '09:00',
        ends_at: this.formattedHoursAndMinutes(moment('09:00', 'HH:mm').add('8', 'hours'))
      }
    }

    this.setState({
      ...autoSettings,
      project: project,
      project_id: project.id
    }, () => {
      this.removeErrorsFor('project_id');
      this.recountTime();
    })
  }

  formattedHoursAndMinutes (time) {
    let hours = moment(time).hours();
    let minutes = moment(time).minutes();
    if (hours < 10) hours = `0${hours}`;
    if (minutes < 10) minutes = `0${minutes}`;

    return `${hours}:${minutes}`;
  }

  recountTime () {
    let formattedStartsAt = moment(this.state.starts_at, 'HH:mm');
    let formattedEndsAt   = moment(this.state.ends_at, 'HH:mm');

    let duration = this.state.project.count_duration ? moment(formattedEndsAt.diff(formattedStartsAt)) : 0;

    this.setState({
      duration: duration._i,
      durationHours: moment(duration - (60 * 60 * 1000)).format('HH:mm'),
      starts_at: this.formattedHoursAndMinutes(formattedStartsAt),
      ends_at: this.formattedHoursAndMinutes(formattedEndsAt)
    }, () => {
      this.removeErrorsFor('duration')
    })
  }

  onFocus (e) {
    e.target.setSelectionRange(0, e.target.value.length)
  }

  _renderEasterEgg () {
    let easters = ['https://media.giphy.com/media/eorpEE4PYJfQQ/giphy.gif',
                   'https://media.tenor.com/images/cd9b58f5b362c24addbcb904c917ebdb/tenor.gif',
                   'https://media1.tenor.com/images/c10b4e9e6b6d2835b19f42cbdd276774/tenor.gif?itemid=10644609'];

    if (moment().format('d') === '4') {
      return 'https://thumbs.gfycat.com/AngelicFailingAlaskajingle-size_restricted.gif';
    } else {
      return _.shuffle(easters)[0];
    }
  }

  render () {
    const { duration, body, task, starts_at, ends_at, durationHours, date, errors, project } = this.state;

    return (
      <div className="new-entry">
        <div className="timer">
          <div className="segment ui">
            <div className="field">
              <div className="desc">
                { errors.body ? <ErrorTooltip errors={errors.body} /> : null }
                <div className="input transparent ui">
                  { project.lunch ?
                      <div className="easter" style={{ 'background-image': `url(${this._renderEasterEgg()})` }}></div>
                    : <textarea className="description auto-focus" placeholder={I18n.t('apps.timesheet.what_have_you_done')} name="body" value={body} onChange={this.onChange}></textarea>
                  }
                </div>
                { project.work_times_allows_task ?
                  <div className="input task-url transparent ui">
                    <input className="task" placeholder={I18n.t('apps.timesheet.task_url')} type="text" name="task" onChange={this.onChange} />
                  </div> : null }
              </div>
              <div className="projects">
                <div className="project-dropdown">
                  { errors.project_id ? <ErrorTooltip errors={errors.project_id} /> : null }
                  <div>
                    <ProjectsDropdown ref={(projectsDropdown) => { this.projectsDropdown = projectsDropdown }} updateProject={this.updateProject} projects={this.props.projects} />
                  </div>
                </div>
              </div>
              <div className="time">
                <div className="input transparent ui">
                  <input className="auto-focus" id="start" type="text" name="starts_at" onChange={this.onChange} onClick={this.onFocus} onBlur={this.recountTime} value={starts_at} />
                </div>
                <span>-</span>
                <div className="input transparent ui">
                  <input className="auto-focus" id="end" type="text" name="ends_at" onChange={this.onChange} onClick={this.onFocus} onBlur={this.recountTime} value={ends_at} />
                </div>
              </div>
              <div className="duration manual">
                { errors.duration ? <ErrorTooltip errors={errors.duration} /> : null }
                <span id="duration">{durationHours}</span>
              </div>
              <div className="date">
                <DatePicker value={date} onChange={this.onDateChange} onSelect={this.onDateChange}/>
              </div>
              <div className="action">
                <button className="btn-start button fluid ui" onClick={this.onSubmit}>Zapisz</button>
              </div>
            </div>
          </div>
        </div>
      </div>
    )
  }
}

export default Entry;
