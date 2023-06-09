--esto lo borramos despues
drop table IF EXISTS ESTADO cascade ;
drop table IF EXISTS ANIO cascade ;
drop table IF EXISTS NIVEL_EDUCACION cascade ;
drop table IF EXISTS BIRTHS;
drop trigger IF EXISTS insertarDatosTablaDefinitiva ON BIRTHS;

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


--funcion para saber si es año biciesto

CREATE OR REPLACE FUNCTION esBiciesto(anio INT) RETURNS BOOLEAN AS $$
	BEGIN
		RETURN anio % 4 = 0 AND (anio % 100 != 0 OR anio % 400 = 0);
	END;
$$ LANGUAGE plpgSQL;


--funcion para generar los ids de las tablas

CREATE OR REPLACE FUNCTION getEstadoID() RETURNS ESTADO.id%TYPE AS $$
    DECLARE
        nextID ESTADO.id%TYPE;
        prevID INT;
    BEGIN
        SELECT COALESCE(MAX(CAST(id AS INT)), 0) INTO prevID FROM ESTADO;
        nextID := CAST((prevID + 1) AS VARCHAR(30));
        RETURN nextID;
    END;
$$ LANGUAGE plpgSQL;

CREATE OR REPLACE FUNCTION getAnioID() RETURNS ANIO.anio%TYPE AS $$
	DECLARE
		nextID ANIO.anio%TYPE;
		prevID INT;
	BEGIN
		SELECT COALESCE(MAX(anio), 0) INTO prevID FROM ANIO;
		nextID := prevID + 1;
		RETURN nextID;
	END;
$$ LANGUAGE plpgSQL;

CREATE OR REPLACE FUNCTION getNivelEducacionID() RETURNS NIVEL_EDUCACION.id%TYPE AS $$
	DECLARE
		nextID NIVEL_EDUCACION.id%TYPE;
		prevID INT;
	BEGIN
		SELECT COALESCE(MAX(CAST(id AS INT)), 0) INTO prevID FROM NIVEL_EDUCACION;
		nextID := CAST((prevID + 1) AS VARCHAR(10));
		RETURN nextID;
	END;

$$ LANGUAGE plpgSQL;


--triggers

CREATE OR REPLACE FUNCTION insertarDatosTablaDefinitiva() RETURNS trigger AS $$
	DECLARE
		id_estado ESTADO.id%TYPE;
	    id_anio ANIO.anio%TYPE;
	    id_nivel_educacion NIVEL_EDUCACION.id%TYPE;

	BEGIN

	    IF new.state NOT IN (SELECT nombre FROM ESTADO) THEN
            id_estado = getEstadoID();
		    INSERT INTO ESTADO VALUES (id_estado, new.state);
		ELSE
			id_estado := (SELECT id FROM ESTADO WHERE nombre = new.state);
		END IF;

		IF new.year NOT IN (SELECT anio FROM ANIO) THEN
			id_anio = getAnioID();
		    INSERT INTO ANIO VALUES (id_anio, new.year);
		ELSE
			id_anio := (SELECT anio FROM ANIO WHERE anio = new.year);
		END IF;

	    IF new.mother_education_level NOT IN (SELECT descripcion FROM NIVEL_EDUCACION) THEN
			id_nivel_educacion = getNivelEducacionID();
		    INSERT INTO NIVEL_EDUCACION VALUES (id_nivel_educacion, new.mother_education_level);
		ELSE
			id_nivel_educacion := (SELECT id FROM NIVEL_EDUCACION WHERE descripcion = new.mother_education_level);
		END IF;

	END;

$$ LANGUAGE plpgSQL;

CREATE TRIGGER insertarDatosTablaDefinitiva
	BEFORE INSERT ON BIRTHS
	FOR EACH ROW
	EXECUTE PROCEDURE insertarDatosTablaDefinitiva();


--copiamos los datos del csv a la tabla definitiva

\COPY BIRTHS(state, state_abbreviation, year, gender, mother_education_level, education_level_code, births, mother_average_age, average_birth_weight) FROM 'us_births_2016_2021.csv' DELIMITER ',' CSV HEADER;


--funcion ReporteConsolidado(n)

CREATE OR REPLACE FUNCTION ReporteConsolidado(cantidad_de_anios INT) RETURNS VOID RETURNS NULL ON NULL INPUT AS $$
    BEGIN
		-- todo
	END;
$$ LANGUAGE plpgSQL;
