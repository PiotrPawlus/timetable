json.id work_time.id
json.updated_by_admin work_time.updated_by_admin
json.project_id work_time.project_id
json.starts_at work_time.starts_at
json.ends_at work_time.ends_at
json.duration work_time.duration
json.body sanitize(work_time.body)
json.task sanitize(work_time.task)
json.task_preview sanitize(task_preview_helper(work_time.task))
json.user_id work_time.user_id
json.project work_time.project, :id, :name, :color, :work_times_allows_task, :lunch, :count_duration
json.date work_time.starts_at.to_date
