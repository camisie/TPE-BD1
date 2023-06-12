--esto lo borramos despues
drop table IF EXISTS ESTADO cascade ;
drop table IF EXISTS ANIO cascade ;
drop table IF EXISTS NIVEL_EDUCACION cascade ;
drop table IF EXISTS BIRTHS;
drop trigger IF EXISTS insertarDatosTablaDefinitiva ON BIRTHS;

-- Tablas de las dimensiones

CREATE TABLE ESTADO (
	id VARCHAR(10),
	nombre CHAR(30),
	PRIMARY KEY(id)
);

CREATE TABLE ANIO (
	anio INT NOT NULL,
	bisiesto BOOLEAN,
	PRIMARY KEY (anio)
);

CREATE TABLE NIVEL_EDUCACION (
	nivel VARCHAR(10),
	descripcion CHAR(100),
	PRIMARY KEY (nivel)
);


-- Tabla definitiva

CREATE TABLE BIRTHS (
	state VARCHAR(30),
	state_abbreviation VARCHAR(10),
	year INT,
	gender CHAR(1),
	mother_education_level VARCHAR(100),
	education_level_code VARCHAR(10),
	births INT,
	mother_average_age FLOAT,
	average_birth_weight FLOAT,

	FOREIGN KEY (state) REFERENCES ESTADO,
	FOREIGN KEY (state_abbreviation) REFERENCES ESTADO,
	FOREIGN KEY (year) REFERENCES ANIO(anio),
	FOREIGN KEY (mother_education_level) REFERENCES NIVEL_EDUCACION,
	FOREIGN KEY (education_level_code) REFERENCES NIVEL_EDUCACION
);


--funcion para saber si es año biciesto

CREATE OR REPLACE FUNCTION esBiciesto(anio INT) RETURNS BOOLEAN AS $$
	BEGIN
		RETURN anio % 4 = 0 AND (anio % 100 != 0 OR anio % 400 = 0);
	END;
$$ LANGUAGE plpgSQL;

--trigger

CREATE OR REPLACE FUNCTION insertarDatosTablaDefinitiva() RETURNS trigger AS $$
	DECLARE
		id_estado ESTADO.id%TYPE;
	    id_anio ANIO.anio%TYPE;
	    id_nivel_educacion NIVEL_EDUCACION.nivel%TYPE;

	BEGIN

	    IF new.state NOT IN (SELECT nombre FROM ESTADO) THEN
            id_estado = new.state_abbreviation;
		    INSERT INTO ESTADO VALUES (id_estado, new.state);
		ELSE
			id_estado := (SELECT id FROM ESTADO WHERE nombre = new.state);
		END IF;

		IF new.year NOT IN (SELECT anio FROM ANIO) THEN
			id_anio = new.year;
		    INSERT INTO ANIO VALUES (id_anio, esBiciesto(new.year));
		ELSE
			id_anio := (SELECT anio FROM ANIO WHERE anio = new.year);
		END IF;

	    IF new.mother_education_level NOT IN (SELECT descripcion FROM NIVEL_EDUCACION) THEN
			id_nivel_educacion = new.education_level_code;
		    INSERT INTO NIVEL_EDUCACION VALUES (id_nivel_educacion, new.mother_education_level);
		ELSE
			id_nivel_educacion := (SELECT nivel FROM NIVEL_EDUCACION WHERE descripcion = new.mother_education_level);
		END IF;

	    new.state := id_estado;
	    new.year := id_anio;
	    new.mother_education_level := id_nivel_educacion;

        return new;

	END;

$$ LANGUAGE plpgSQL;

CREATE TRIGGER insertarDatosTablaDefinitiva
BEFORE INSERT ON BIRTHS
FOR EACH ROW
EXECUTE PROCEDURE insertarDatosTablaDefinitiva();


--copiamos los datos del csv a la tabla definitiva

\COPY BIRTHS(state, state_abbreviation, year, gender, mother_education_level, education_level_code, births, mother_average_age, average_birth_weight) FROM 'us_births_2016_2021.csv' DELIMITER ',' CSV HEADER;
-- select * from BIRTHS;
-- SELECT * FROM estado;
-- SELECT * FROM anio;
-- SELECT * FROM nivel_educacion;


--funcion ReporteConsolidado(n)

CREATE OR REPLACE FUNCTION ReporteConsolidado(cantidad_de_anios INT) RETURNS VOID RETURNS NULL ON NULL INPUT AS $$
    BEGIN
		-- todo
	END;
$$ LANGUAGE plpgSQL;
