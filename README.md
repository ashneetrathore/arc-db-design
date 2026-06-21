# :weight_lifting: THE ARC DATABASE DESIGN

## :open_book: OVERVIEW
Date: October 2023\
Designer(s): Ashneet Rathore, Guillermo Bolger

This repository presents a relational database design for the Anteater Recreation Center (ARC), a gym located on the University of California, Irvine campus. The purpose of the database is to support core gym operations such as member management, event enrollment, employee scheduling, and facility usage. The project consists of three main artifacts: an **entity relationship diagram (ERD)**, a **relational notation** document, and a **schema** implementation with a **MySQL** script. 

The repo also includes a system requirements narrative that informed the modeling decisions and schema constraints throughout the design process. Certain requirements, such as the presence of sensor technology, were intentionally extended for design exploration purposes and do not necessarily reflect current ARC operations.

## :brain: DESIGN RATIONALE
Relationships in the ERD are represented in the final schema in two main ways:
1. Some relationships translate to the addition of foreign keys. For example, the relationship between the `Equipment` and `Room` entities, titled *belongs to*, translates to a foreign key `room_id` that references the `id` column of `Room`.
2. Other relationships become independent tables. For example, the relationship between the `Person` and `Room` entities with the relationship attribute `entry_time`, titled *located in*, translates to the `LocationLog` table with the composite key `(person_id, room_id, entry_time)`.

> [!NOTE]
> Some of the columns in the tables aren't explicitly included as attributes in the ERD for simplicity. For example, in the `Member` table, the columns `street_address1`, `city`, `zip`, etc are combined anad represented as the `address` attribute in the `Member` entity in the ERD.

Instead of having multiple layers of sub-entities under `Member` (e.g. `Student` -> `Undergrad Student` \ `Grad Student`), the schema uses a single `Member` entity with a `member_type` attribute, with a restricted domain of predefined options, such as `Undergrad_Student`, `Grad_Student`, etc. An optional `relation_to` foreign key is included to support family memberships - that is, when `member_type` is `Family`, this attribute stores the `id` of the `Member` to whom the family member is associated. This design simplifies the schema, as the sub-entities did not have many distinct attributes. The same approach is applied to the `Employee` entity.

The logging of a person's entrance into the ARC is separated from the logging of a person's entrance into a room by using two tables: `EntryLog` and `LocationLog`. This separation is due to the fact that entering the ARC is a building-level event, since the ARC is not modeled as a room itself, while entering a room is a location-level event that must be associated with a specific room. 

The `Equipment` table includes an `in_use` Boolean attribute, indicating whether a piece of equipment is currently being used or not. Regarding specifically the pool, each lane is modeled as a separate piece of equipment. When one lane is occupied, it's associated `in_use` attribute is marked as `TRUE` and the associated `in_use_by` attribute is updated with the `id` of the member currently using the lane.

Two triggers are implemented in the MySQL script to enforce event-related constraints. The first trigger ensures that when a new event in inserted, the event's maximum capacity does not exceed the maximum capacity of the room in which it takes place. The second trigger ensures that upon enrolling in an event, the count of the total people enrolled does not exceed the event's maximum capacity.

The `PaymentInfo` table is designed to avoid storing sensitive payment details, such as credit card numbers, in compliance with data protection standards. Instead, each payment method is represented by a token called `payment_ref`, which can safely reference the underlying payment method. Each member can have at most one payment method, so `member_id` is used as the primary key of the `PaymentInfo` table, however note that the `payment_ref` column is not unique, meaning multiple members can use the same payment method.

## :key: ERD NOTATION KEY

| Notation                   | Meaning                                                 |
|----------------------------|---------------------------------------------------------|
| Rectangle (single border)  | Strong entity                                           |
| Rectangle (double border)  | Weak entity                                             |
| Diamond (single border)    | Regular relationship                                    | 
| Diamond (double border)    | Identifying relationship                                |
| IS A relationship          | Inheritance relationship                                |
| Oval with "o"              | Overlapping specialization                              |
| Oval                       | Relationship attribute                                  |
| Underlined attribute       | Primary key                                             |
| Italicized attribute       | Partial key                                             |
| Double line                | Total participation                                     |
| Single line                | Optional participation                                  | 
| Line ending with arrow     | "One" side of a 1-to-1 or 1-to-many relationship        |
| Line ending with no arrow  | "Many" side of a 1-to-many or many-to-many relationship | 