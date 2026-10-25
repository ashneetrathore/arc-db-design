DROP DATABASE IF EXISTS arc_management;
CREATE DATABASE arc_management;
USE arc;

CREATE TABLE Person (
id INT PRIMARY KEY,
first_name VARCHAR(50) NOT NULL,
last_name VARCHAR(50) NOT NULL
);

CREATE TABLE Member (
id INT PRIMARY KEY,
street_address1 VARCHAR(50) NOT NULL,
street_address2 VARCHAR(50),
city VARCHAR(50) NOT NULL,
zip VARCHAR(10) NOT NULL,
member_type ENUM('Undergrad_Student', 'Grad_Student', 'Faculty', 'Staff', 'Alumni', 'Family') NOT NULL,
relation_to INT,
FOREIGN KEY (id) REFERENCES Person(id),
FOREIGN KEY (relation_to) REFERENCES Member(id),
CHECK (
	(member_type = 'Family' AND relation_to IS NOT NULL)
	OR
	(member_type <> 'Family' AND relation_to IS NULL)
	)
);

CREATE TABLE Employee (
id INT PRIMARY KEY,
designation ENUM('Trainer', 'Desk_Emp') NOT NULL,
FOREIGN KEY (id) REFERENCES Person(id)
);

CREATE TABLE EmployeeShift(
shift_id INT AUTO_INCREMENT PRIMARY KEY,
emp_id INT NOT NULL,
work_day ENUM('Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun') NOT NULL,
start_time TIME NOT NULL,
end_time TIME NOT NULL,
FOREIGN KEY (emp_id) REFERENCES Employee(id)
);

CREATE TABLE PaymentInfo(
member_id INT PRIMARY KEY,
payment_ref VARCHAR(20) NOT NULL,
FOREIGN KEY (member_id) REFERENCES Member(id)
);

CREATE TABLE Room (
id INT AUTO_INCREMENT PRIMARY KEY,
name ENUM('Front_Desk', 'Cardio', 'Weight', 'Pool', 'Yoga', 'Basketball_Court', 'Other') NOT NULL,
max_capacity INT NOT NULL
);

CREATE TABLE Equipment (
id INT AUTO_INCREMENT PRIMARY KEY,
name VARCHAR(100) NOT NULL,
room_id INT NOT NULL,
in_use BOOLEAN NOT NULL,
in_use_by INT,
FOREIGN KEY (room_id) REFERENCES Room(id),
FOREIGN KEY (in_use_by) REFERENCES Member(id),
CHECK(
	(in_use = TRUE and in_use_by IS NOT NULL)
	OR
	(in_use = FALSE and in_use_by IS NULL)
	)
);

CREATE TABLE EntryLog (
person_id INT,
entry_time TIMESTAMP,
PRIMARY KEY (person_id, entry_time),
FOREIGN KEY (person_id) REFERENCES Person(id)
);

CREATE TABLE EmployeeExitLog (
emp_id INT,
exit_time TIMESTAMP,
PRIMARY KEY (emp_id, exit_time),
FOREIGN KEY (emp_id) REFERENCES Employee(id)
);

CREATE TABLE LocationLog(
person_id INT,
room_id INT,
entry_time TIMESTAMP,
PRIMARY KEY (person_id, room_id, entry_time),
FOREIGN KEY (person_id) REFERENCES Person(id),
FOREIGN KEY (room_id) REFERENCES Room(id)
);

CREATE TABLE Event(
id INT AUTO_INCREMENT PRIMARY KEY,
name VARCHAR(100) NOT NULL,
room_id INT NOT NULL,
max_capacity INT NOT NULL,
start_time DATETIME NOT NULL,
end_time DATETIME NOT NULL,
FOREIGN KEY (room_id) REFERENCES Room(id)
);

CREATE TABLE EventEnrollment(
event_id INT,
member_id INT,
PRIMARY KEY (event_id, member_id),
FOREIGN KEY (event_id) REFERENCES Event(id),
FOREIGN KEY (member_id) REFERENCES Member(id)
);

DELIMITER $$
 
-- Trigger 1: Ensure Event.max_capacity <= Room.max_capacity
CREATE TRIGGER check_room_capacity_for_event
BEFORE INSERT ON Event
FOR EACH ROW
BEGIN
    DECLARE room_max INT;

    -- Get the maximum capacity of the room
    SELECT max_capacity
    INTO room_max
    FROM Room
    WHERE id = NEW.room_id;

    -- Prevent event creation if event capacity exceeds room capacity
    IF NEW.max_capacity > room_max THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'ERROR: Cannot create event. Event capacity exceeds room capacity';
    END IF;
END$$

-- Trigger 2: Ensure the enrollment for an event does not exceed Event.max_capacity
CREATE TRIGGER check_event_capacity
BEFORE INSERT ON EventEnrollment
FOR EACH ROW
BEGIN
    DECLARE curr_enrolled INT;
    DECLARE event_capacity INT;

    -- Count current enrollments for the event
    SELECT COUNT(*)
    INTO curr_enrolled
    FROM EventEnrollment
    WHERE event_id = NEW.event_id;

    -- Get the maximum capacity for the event
    SELECT max_capacity
    INTO event_capacity
    FROM Event
    WHERE id = NEW.event_id;

    -- Prevent insertion if capacity is reached
    IF curr_enrolled >= event_capacity THEN
		-- Raise a user-defined exception
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'ERROR: Cannot enroll member. Event capacity has been reached';
    END IF;
END$$

DELIMITER ;