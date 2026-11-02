-- Таблица пользователей
CREATE TABLE app.users (
    user_id SERIAL PRIMARY KEY,
    username VARCHAR(50) UNIQUE NOT NULL,
    email VARCHAR(100) UNIQUE NOT NULL,
    password_hash VARCHAR(255) NOT NULL,
    full_name VARCHAR(100),
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Таблица проектов
CREATE TABLE app.projects (
    project_id SERIAL PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    description TEXT,
    owner_id INTEGER REFERENCES app.users(user_id),
    status VARCHAR(20) DEFAULT 'active'
        CHECK (status IN ('active', 'completed', 'archived')),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Таблица задач
CREATE TABLE app.tasks (
    task_id SERIAL PRIMARY KEY,
    project_id INTEGER REFERENCES app.projects(project_id),
    title VARCHAR(200) NOT NULL,
    description TEXT,
    status VARCHAR(20) DEFAULT 'todo'
        CHECK (status IN ('todo', 'in_progress', 'done')),
    priority INTEGER DEFAULT 3 CHECK (priority BETWEEN 1 AND 5),
    assignee_id INTEGER REFERENCES app.users(user_id),
    created_by INTEGER REFERENCES app.users(user_id),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Таблица комментариев к задачам
CREATE TABLE app.comments (
    comment_id SERIAL PRIMARY KEY,
    task_id INTEGER REFERENCES app.tasks(task_id),
    user_id INTEGER REFERENCES app.users(user_id),
    content TEXT NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Таблица истории изменений задач
CREATE TABLE app.task_history (
    history_id SERIAL PRIMARY KEY,
    task_id INTEGER REFERENCES app.tasks(task_id),
    changed_by INTEGER REFERENCES app.users(user_id),
    changed_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    field_name VARCHAR(50) NOT NULL,
    old_value TEXT,
    new_value TEXT
);

-- Таблица логов доступа
CREATE TABLE app.access_logs (
    log_id SERIAL PRIMARY KEY,
    user_id INTEGER REFERENCES app.users(user_id),
    action VARCHAR(50) NOT NULL,
    resource_type VARCHAR(50),
    resource_id INTEGER,
    ip_address INET,
    logged_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);


-- Добавление пользователей
INSERT INTO app.users (username, email, password_hash, full_name) VALUES
('alice', 'alice@company.com', 'hash1', 'Alice Johnson'),
('bob', 'bob@company.com', 'hash2', 'Bob Smith'),
('charlie', 'charlie@company.com', 'hash3', 'Charlie Brown'),
('diana', 'diana@company.com', 'hash4', 'Diana Prince'),
('eve', 'eve@company.com', 'hash5', 'Eve Wilson');

-- Добавление проектов
INSERT INTO app.projects (name, description, owner_id, status) VALUES
('Website Redesign', 'Redesign company website', 1, 'active'),
('Mobile App', 'Develop mobile application', 2, 'active');

-- Добавление задач
INSERT INTO app.tasks
(project_id, title, description, status, priority, assignee_id, created_by)
VALUES
(1, 'Design homepage', 'Create new homepage design', 'in_progress', 1, 1, 1),
(1, 'Implement navigation', 'Add responsive navigation', 'todo', 2, 2, 1),
(2, 'Setup project', 'Initialize project', 'done', 1, 3, 2),
(2, 'Create login screen', 'Create login page', 'in_progress', 2, 4, 2),
(2, 'API integration', 'Connect to backend API', 'todo', 3, 3, 2),
(1, 'Prepare logo', 'Create company logo', 'todo', 3, 5, 1),
(1, 'Check mobile layout', 'Test mobile version', 'todo', 2, 2, 1),
(1, 'Update footer', 'Change website footer', 'done', 4, 3, 1),
(2, 'Test login', 'Check login function', 'todo', 2, 5, 2),
(2, 'Write documentation', 'Describe project', 'todo', 3, 4, 2);


-- Проверка пользователей
SELECT * FROM app.users;

-- Проверка проектов
SELECT * FROM app.projects;

-- Проверка задач
SELECT * FROM app.tasks;


-- Задание 2.3. Реализация RBAC-модели

-- Шаг 1. Создание ролей
CREATE ROLE app_guest;
CREATE ROLE app_employee;
CREATE ROLE app_manager;
CREATE ROLE app_admin;
CREATE ROLE app_superuser;

-- Шаг 2. Права на подключение и использование схемы
GRANT CONNECT ON DATABASE task_management TO app_guest;
GRANT USAGE ON SCHEMA app TO app_guest;

GRANT CONNECT ON DATABASE task_management TO app_employee;
GRANT USAGE ON SCHEMA app TO app_employee;

-- Шаг 3. Права гостя
GRANT SELECT ON TABLE app.projects TO app_guest;

-- Шаг 4. Права сотрудника
GRANT SELECT (user_id, username, full_name)
ON TABLE app.users TO app_employee;

GRANT SELECT ON TABLE app.projects TO app_employee;
GRANT SELECT ON TABLE app.tasks TO app_employee;

GRANT SELECT, INSERT ON TABLE app.tasks TO app_employee;
GRANT USAGE ON SEQUENCE app.tasks_task_id_seq TO app_employee;

GRANT SELECT, INSERT ON TABLE app.comments TO app_employee;
GRANT USAGE ON SEQUENCE app.comments_comment_id_seq TO app_employee;

GRANT SELECT ON TABLE app.task_history TO app_employee;

-- Шаг 5. Права менеджера
GRANT app_employee TO app_manager;

GRANT SELECT, INSERT, UPDATE
ON TABLE app.projects TO app_manager;

GRANT SELECT, INSERT, UPDATE, DELETE
ON TABLE app.tasks TO app_manager;

GRANT SELECT, INSERT, DELETE
ON TABLE app.comments TO app_manager;

GRANT SELECT ON TABLE app.task_history TO app_manager;
GRANT INSERT ON TABLE app.task_history TO app_manager;

-- Шаг 6. Права администратора
GRANT app_manager TO app_admin;

GRANT SELECT, INSERT, UPDATE ON TABLE app.users TO app_admin;

GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA app TO app_admin;
GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA app TO app_admin;

GRANT CREATE ON SCHEMA app TO app_admin;

-- Шаг 7. Права роли superuser
GRANT app_admin TO app_superuser;

GRANT ALL PRIVILEGES ON DATABASE task_management TO app_superuser;

-- Шаг 8. Создание пользователей
CREATE USER alice WITH PASSWORD 'AliceSecure123!';
CREATE USER bob WITH PASSWORD 'BobSecure456!';
CREATE USER charlie WITH PASSWORD 'CharlieSecure789!';
CREATE USER diana WITH PASSWORD 'DianaSecure012!';
CREATE USER eve WITH PASSWORD 'EveSecure345!';

-- Назначение ролей пользователям
GRANT app_manager TO alice;

GRANT app_employee TO bob;
GRANT app_employee TO charlie;

GRANT app_admin TO diana;

GRANT app_superuser TO eve;


-- Шаг 9. Проверка созданных ролей
SELECT rolname
FROM pg_roles
WHERE rolname IN (
    'app_guest',
    'app_employee',
    'app_manager',
    'app_admin',
    'app_superuser'
)
ORDER BY rolname;

-- Проверка наследования ролей
SELECT
    r.rolname AS role_name,
    m.rolname AS member_name
FROM pg_auth_members am
JOIN pg_roles r ON am.roleid = r.oid
JOIN pg_roles m ON am.member = m.oid
WHERE r.rolname LIKE 'app_%'
ORDER BY role_name, member_name;

-- Проверка прав доступа
SELECT grantee, table_name, privilege_type
FROM information_schema.role_table_grants
WHERE table_schema = 'app'
AND grantee IN (
    'app_guest',
    'app_employee',
    'app_manager',
    'app_admin',
    'app_superuser'
)
ORDER BY grantee, table_name, privilege_type;


-- Задание 2.5. Настройка RLS

-- Политика 1. Ограничение доступа к задачам

ALTER TABLE app.tasks ENABLE ROW LEVEL SECURITY;

-- Сотрудники видят свои и общие задачи
CREATE POLICY employee_tasks_select ON app.tasks
FOR SELECT
TO app_employee
USING (
    assignee_id = (
        SELECT user_id FROM app.users
        WHERE username = current_user
    )
    OR assignee_id IS NULL
);

-- Сотрудники могут создавать свои и общие задачи
CREATE POLICY employee_tasks_insert ON app.tasks
FOR INSERT
TO app_employee
WITH CHECK (
    assignee_id = (
        SELECT user_id FROM app.users
        WHERE username = current_user
    )
    OR assignee_id IS NULL
);

-- Сотрудники могут обновлять только свои задачи
CREATE POLICY employee_tasks_update ON app.tasks
FOR UPDATE
TO app_employee
USING (
    assignee_id = (
        SELECT user_id FROM app.users
        WHERE username = current_user
    )
);

-- Политика 2. Права менеджера

CREATE POLICY manager_tasks_all ON app.tasks
FOR ALL
TO app_manager
USING (TRUE)
WITH CHECK (TRUE);

-- Политика 3. Доступ к данным пользователей

ALTER TABLE app.users ENABLE ROW LEVEL SECURITY;

-- Сотрудники могут просматривать разрешенные данные
CREATE POLICY users_employee_select ON app.users
FOR SELECT
TO app_employee
USING (TRUE);

-- Изменение только своих данных
CREATE POLICY users_employee_update ON app.users
FOR UPDATE
TO app_employee
USING (
    username = current_user
);
