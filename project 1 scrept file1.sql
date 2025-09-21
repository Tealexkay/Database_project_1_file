create database Learning_App;

use learning_app;

CREATE TABLE users (
  id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  full_name VARCHAR(100) NOT NULL,
  email VARCHAR(255) NOT NULL,
  password_hash VARCHAR(255) NOT NULL,
  role ENUM('learner','instructor','admin') NOT NULL DEFAULT 'learner',
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (id),
  UNIQUE KEY uq_users_email (email)
) ENGINE=InnoDB;

CREATE TABLE courses (
  id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  instructor_id BIGINT UNSIGNED NOT NULL,
  title VARCHAR(150) NOT NULL,
  description TEXT NULL,
  level ENUM('beginner','intermediate','advanced') NOT NULL DEFAULT 'beginner',
  is_published BOOLEAN NOT NULL DEFAULT FALSE,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (id),
  KEY idx_courses_instructor (instructor_id),
  CONSTRAINT fk_courses_instructor
    FOREIGN KEY (instructor_id) REFERENCES users(id)
    ON UPDATE CASCADE ON DELETE RESTRICT
) ENGINE=InnoDB;

CREATE TABLE modules (
  id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  course_id BIGINT UNSIGNED NOT NULL,
  title VARCHAR(150) NOT NULL,
  position INT NOT NULL,
  PRIMARY KEY (id),
  UNIQUE KEY uq_modules_course_position (course_id, position),
  KEY idx_modules_course (course_id),
  CONSTRAINT fk_modules_course
    FOREIGN KEY (course_id) REFERENCES courses(id)
    ON UPDATE CASCADE ON DELETE CASCADE
) ENGINE=InnoDB;

CREATE TABLE lessons (
  id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  module_id BIGINT UNSIGNED NOT NULL,
  title VARCHAR(150) NOT NULL,
  video_url VARCHAR(255) NULL,
  content TEXT NULL,
  position INT NOT NULL,
  duration_minutes INT NULL,
  is_free_preview BOOLEAN NOT NULL DEFAULT FALSE,
  PRIMARY KEY (id),
  UNIQUE KEY uq_lessons_module_position (module_id, position),
  KEY idx_lessons_module (module_id),
  CONSTRAINT fk_lessons_module
    FOREIGN KEY (module_id) REFERENCES modules(id)
    ON UPDATE CASCADE ON DELETE CASCADE
) ENGINE=InnoDB;

CREATE TABLE subscription_plans (
  id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  name VARCHAR(100) NOT NULL,
  billing_period ENUM('monthly','annual') NOT NULL,
  price_cents INT UNSIGNED NOT NULL CHECK (price_cents >= 0),
  currency CHAR(3) NOT NULL DEFAULT 'USD',
  max_active_courses INT UNSIGNED NOT NULL DEFAULT 999,
  PRIMARY KEY (id)
) ENGINE=InnoDB;

CREATE TABLE subscriptions (
  id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  user_id BIGINT UNSIGNED NOT NULL,
  plan_id BIGINT UNSIGNED NOT NULL,
  status ENUM('active','past_due','canceled','expired') NOT NULL,
  start_date DATE NOT NULL,
  end_date DATE NULL,
  auto_renew BOOLEAN NOT NULL DEFAULT TRUE,
  PRIMARY KEY (id),
  KEY idx_subscriptions_user_status (user_id, status),
  KEY idx_subscriptions_plan (plan_id),
  CONSTRAINT fk_subscriptions_user
    FOREIGN KEY (user_id) REFERENCES users(id)
    ON UPDATE CASCADE ON DELETE CASCADE,
  CONSTRAINT fk_subscriptions_plan
    FOREIGN KEY (plan_id) REFERENCES subscription_plans(id)
    ON UPDATE CASCADE ON DELETE RESTRICT
) ENGINE=InnoDB;

CREATE TABLE payments (
  id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  subscription_id BIGINT UNSIGNED NOT NULL,
  paid_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  amount_cents INT UNSIGNED NOT NULL,
  currency CHAR(3) NOT NULL DEFAULT 'USD',
  receipt_number VARCHAR(50) NOT NULL,
  provider ENUM('cash','card','paypal','stripe') NOT NULL,
  PRIMARY KEY (id),
  UNIQUE KEY uq_payments_receipt (receipt_number),
  KEY idx_payments_subscription (subscription_id),
  CONSTRAINT fk_payments_subscription
    FOREIGN KEY (subscription_id) REFERENCES subscriptions(id)
    ON UPDATE CASCADE ON DELETE CASCADE
) ENGINE=InnoDB;

CREATE TABLE enrollments (
  user_id BIGINT UNSIGNED NOT NULL,
  course_id BIGINT UNSIGNED NOT NULL,
  enrolled_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (user_id, course_id),
  KEY idx_enrollments_course (course_id),
  CONSTRAINT fk_enrollments_user
    FOREIGN KEY (user_id) REFERENCES users(id)
    ON UPDATE CASCADE ON DELETE CASCADE,
  CONSTRAINT fk_enrollments_course
    FOREIGN KEY (course_id) REFERENCES courses(id)
    ON UPDATE CASCADE ON DELETE CASCADE
) ENGINE=InnoDB;

CREATE TABLE lesson_progress (
  user_id BIGINT UNSIGNED NOT NULL,
  lesson_id BIGINT UNSIGNED NOT NULL,
  is_completed BOOLEAN NOT NULL DEFAULT FALSE,
  completed_at DATETIME NULL,
  last_position_seconds INT UNSIGNED NOT NULL DEFAULT 0,
  PRIMARY KEY (user_id, lesson_id),
  KEY idx_lp_lesson (lesson_id),
  CONSTRAINT fk_lp_user
    FOREIGN KEY (user_id) REFERENCES users(id)
    ON UPDATE CASCADE ON DELETE CASCADE,
  CONSTRAINT fk_lp_lesson
    FOREIGN KEY (lesson_id) REFERENCES lessons(id)
    ON UPDATE CASCADE ON DELETE CASCADE
) ENGINE=InnoDB;

CREATE TABLE quizzes (
  id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  lesson_id BIGINT UNSIGNED NOT NULL,
  title VARCHAR(150) NULL,
  pass_mark INT NOT NULL DEFAULT 70 CHECK (pass_mark BETWEEN 0 AND 100),
  PRIMARY KEY (id),
  UNIQUE KEY uq_quizzes_lesson (lesson_id),
  CONSTRAINT fk_quizzes_lesson
    FOREIGN KEY (lesson_id) REFERENCES lessons(id)
    ON UPDATE CASCADE ON DELETE CASCADE
) ENGINE=InnoDB;

CREATE TABLE quiz_questions (
  id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  quiz_id BIGINT UNSIGNED NOT NULL,
  prompt TEXT NOT NULL,
  position INT NOT NULL,
  PRIMARY KEY (id),
  UNIQUE KEY uq_questions_quiz_position (quiz_id, position),
  KEY idx_questions_quiz (quiz_id),
  CONSTRAINT fk_questions_quiz
    FOREIGN KEY (quiz_id) REFERENCES quizzes(id)
    ON UPDATE CASCADE ON DELETE CASCADE
) ENGINE=InnoDB;

CREATE TABLE quiz_options (
  id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  question_id BIGINT UNSIGNED NOT NULL,
  option_text VARCHAR(255) NOT NULL,
  is_correct BOOLEAN NOT NULL DEFAULT FALSE,
  PRIMARY KEY (id),
  KEY idx_options_question (question_id),
  CONSTRAINT fk_options_question
    FOREIGN KEY (question_id) REFERENCES quiz_questions(id)
    ON UPDATE CASCADE ON DELETE CASCADE
) ENGINE=InnoDB;

CREATE TABLE quiz_attempts (
  id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  quiz_id BIGINT UNSIGNED NOT NULL,
  user_id BIGINT UNSIGNED NOT NULL,
  started_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  completed_at DATETIME NULL,
  score INT NULL,
  PRIMARY KEY (id),
  KEY idx_attempts_quiz_user (quiz_id, user_id),
  CONSTRAINT fk_attempts_quiz
    FOREIGN KEY (quiz_id) REFERENCES quizzes(id)
    ON UPDATE CASCADE ON DELETE CASCADE,
  CONSTRAINT fk_attempts_user
    FOREIGN KEY (user_id) REFERENCES users(id)
    ON UPDATE CASCADE ON DELETE CASCADE
) ENGINE=InnoDB;

CREATE TABLE attempt_answers (
  attempt_id BIGINT UNSIGNED NOT NULL,
  question_id BIGINT UNSIGNED NOT NULL,
  selected_option_id BIGINT UNSIGNED NULL,
  PRIMARY KEY (attempt_id, question_id),
  KEY idx_aa_option (selected_option_id),
  CONSTRAINT fk_aa_attempt
    FOREIGN KEY (attempt_id) REFERENCES quiz_attempts(id)
    ON UPDATE CASCADE ON DELETE CASCADE,
  CONSTRAINT fk_aa_question
    FOREIGN KEY (question_id) REFERENCES quiz_questions(id)
    ON UPDATE CASCADE ON DELETE CASCADE,
  CONSTRAINT fk_aa_selected_option
    FOREIGN KEY (selected_option_id) REFERENCES quiz_options(id)
    ON UPDATE CASCADE ON DELETE SET NULL
) ENGINE=InnoDB;

CREATE TABLE certificates (
  id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  user_id BIGINT UNSIGNED NOT NULL,
  course_id BIGINT UNSIGNED NOT NULL,
  issued_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  certificate_code VARCHAR(50) NOT NULL,
  PRIMARY KEY (id),
  UNIQUE KEY uq_cert_user_course (user_id, course_id),
  UNIQUE KEY uq_cert_code (certificate_code),
  KEY idx_cert_course (course_id),
  CONSTRAINT fk_cert_user
    FOREIGN KEY (user_id) REFERENCES users(id)
    ON UPDATE CASCADE ON DELETE CASCADE,
  CONSTRAINT fk_cert_course
    FOREIGN KEY (course_id) REFERENCES courses(id)
    ON UPDATE CASCADE ON DELETE CASCADE
) ENGINE=InnoDB;

select * from users;



INSERT INTO users (full_name, email, password_hash, role) VALUES
('Alice Turay','alice@example.com','hash_alice','learner'),
('Bob Ivan','bob@example.com','hash_bob','instructor'),
('Ada Amara','ada@example.com','hash_ada','admin');

INSERT INTO subscription_plans (name, billing_period, price_cents, currency, max_active_courses) VALUES
('Basic Monthly','monthly',990,'USD',10),
('Pro Annual','annual',7990,'USD',999);

INSERT INTO subscriptions (user_id, plan_id, status, start_date, end_date, auto_renew)
VALUES (1, 1, 'active', CURDATE(), DATE_ADD(CURDATE(), INTERVAL 30 DAY), TRUE);

INSERT INTO payments (subscription_id, amount_cents, currency, receipt_number, provider)
VALUES (1, 990, 'USD', 'RCP-0001', 'card');

INSERT INTO courses (instructor_id, title, description, level, is_published)
VALUES (2, 'MySQL for Beginners', 'Start with SQL basics', 'beginner', TRUE);

INSERT INTO modules (course_id, title, position) VALUES
(1, 'Getting Started', 1),
(1, 'Writing Queries', 2);

INSERT INTO lessons (module_id, title, position, duration_minutes) VALUES
(1, 'Welcome & Setup', 1, 8),
(1, 'SELECT Basics', 2, 14),
(2, 'WHERE & ORDER BY', 1, 18);

INSERT INTO enrollments (user_id, course_id) VALUES (1, 1);

INSERT INTO lesson_progress (user_id, lesson_id, is_completed, completed_at, last_position_seconds)
VALUES (1, 1, TRUE, NOW(), 480);

INSERT INTO quizzes (lesson_id, title, pass_mark) VALUES (2, 'SELECT Quiz', 70);

INSERT INTO quiz_questions (quiz_id, prompt, position) VALUES
(1, 'Which clause picks columns?', 1),
(1, 'Which clause filters rows?', 2);

INSERT INTO quiz_options (question_id, option_text, is_correct) VALUES
(1, 'SELECT', TRUE), (1, 'FROM', FALSE), (1, 'WHERE', FALSE),
(2, 'SELECT', FALSE), (2, 'WHERE', TRUE), (2, 'ORDER BY', FALSE);

INSERT INTO quiz_attempts (quiz_id, user_id) VALUES (1, 1);

INSERT INTO attempt_answers (attempt_id, question_id, selected_option_id) VALUES
(1, 1, 1),  -- SELECT
(1, 2, 5);  -- WHERE
UPDATE quiz_attempts SET completed_at = NOW(), score = 100 WHERE id = 1;

INSERT INTO certificates (user_id, course_id, certificate_code)
VALUES (1, 1, 'CERT-ABC-0001');

show tables;


