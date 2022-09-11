CREATE SCHEMA IF NOT EXISTS hospital;

DROP TABLE IF EXISTS hospital.role CASCADE;
DROP TABLE IF EXISTS hospital.user CASCADE;



CREATE TABLE hospital.role (

    id SERIAL PRIMARY KEY,
    role VARCHAR(50) NOT NULL, 
    UNIQUE (id)
);

CREATE TABLE hospital.user (

    id SERIAL,
    name VARCHAR(50) NOT NULL,
    surname VARCHAR(50) NOT NULL,
    hash VARCHAR(100) NOT NULL,
    role int NOT NULL,
    room VARCHAR(50),
    illness VARCHAR(50),

    FOREIGN KEY (role) REFERENCES hospital.role(id),
    PRIMARY KEY (id),
    UNIQUE (id)
);


INSERT INTO hospital.role(id,role) VALUES 
    (1,'SuperUser'),
    (2,'Patient'),
    (3,'Visitor');

insert INTO hospital.user (name, surname, hash, role, room, illness)VALUES
('Arturo','Herrera','32c7be06efeddf145d8693159fa877d9c5d7479db0a6f31d59b377e708111477', 2, 'H22', 'COVID');

insert INTO hospital.user (name, surname, hash, role, room)VALUES
('Sara','Escribano','1f0adfedc20d81ed2eff104a3c9085f8a778e95bcb6a01c7cc062f7caf160a8f', 3, 'H22');

insert INTO hospital.user (name, surname, hash, role)VALUES
('Pedro','Medicman','8117fdfb12f1939e343d71fcb68e4245b9862127b7a53eb51d7b84d4db574903', 1);



COMMIT;
