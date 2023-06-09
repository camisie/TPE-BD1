-- Tablas de las dimensiones

CREATE TABLE ESTADO (
	id VARCHAR(30),
	nombre CHAR(30),
	PRIMARY KEY(id)
);

CREATE TABLE ANIO (
	anio INT NOT NULL,
	bisiesto BOOLEAN,
	PRIMARY KEY (anio)
);

CREATE TABLE NIVEL_EDUCACION (
	id VARCHAR(10),
	descripcion CHAR(100),
	PRIMARY KEY (id)
);

-- Tabla definitiva

CREATE TABLE BIRTHS (
	state VARCHAR(30),
	state_abbreviation VARCHAR(30),
	year INT,
	gender CHAR(1),
	mother_education_level VARCHAR(100),
	education_level_code VARCHAR(10),
	births INT,
	mother_average_age FLOAT,
	average_birth_weight FLOAT,

	FOREIGN KEY (state) REFERENCES ESTADO(id),
	FOREIGN KEY (state_abbreviation) REFERENCES ESTADO(id),
	FOREIGN KEY (year) REFERENCES ANIO(anio),
	FOREIGN KEY (mother_education_level) REFERENCES NIVEL_EDUCACION(id),
	FOREIGN KEY (education_level_code) REFERENCES NIVEL_EDUCACION(id)
);

-- select * from BIRTHS;
-- drop table births;
-- drop table nivel_educacion;





