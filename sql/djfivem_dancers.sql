CREATE TABLE IF NOT EXISTS `djfivem_dancers_placements` (
    `club_id` VARCHAR(64) NOT NULL,
    `pole_id` INT NOT NULL,
    `pos_x` FLOAT NOT NULL,
    `pos_y` FLOAT NOT NULL,
    `pos_z` FLOAT NOT NULL,
    `heading` FLOAT NOT NULL DEFAULT 0,
    PRIMARY KEY (`club_id`, `pole_id`)
);

CREATE TABLE IF NOT EXISTS `djfivem_dancers_active` (
    `club_id` VARCHAR(64) NOT NULL,
    `pole_id` INT NOT NULL,
    `data` LONGTEXT NOT NULL,
    PRIMARY KEY (`club_id`, `pole_id`)
);
