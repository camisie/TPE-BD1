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
	id VARCHAR(30),
	descripcion CHAR(50),
	PRIMARY KEY (id)
);

-- Tabla definitiva

CREATE TABLE BIRTHS (
	id SERIAL,
	state VARCHAR(30),
	state_abbreviation VARCHAR(30),
	year INT,
	gender CHAR(1),
	mother_education_level VARCHAR(50),
	education_level_code VARCHAR(10),
	mother_average_age INT,
	average_birth_weight INT,

	PRIMARY KEY (id),
	FOREIGN KEY (state) REFERENCES ESTADO(id),
	FOREIGN KEY (state_abbreviation) REFERENCES ESTADO(id),
	FOREIGN KEY (year) REFERENCES ANIO(anio),
	FOREIGN KEY (mother_education_level) REFERENCES NIVEL_EDUCACION(id),
	FOREIGN KEY (education_level_code) REFERENCES NIVEL_EDUCACION(id)
)