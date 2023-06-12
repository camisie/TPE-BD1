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


--Funcion para saber si es año bisiesto

CREATE OR REPLACE FUNCTION esBisiesto(anio INT) RETURNS BOOLEAN AS $$
	BEGIN
		RETURN anio % 4 = 0 AND (anio % 100 != 0 OR anio % 400 = 0);
	END;
$$ LANGUAGE plpgSQL;

--Trigger

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
		    INSERT INTO ANIO VALUES (id_anio, esBisiesto(new.year));
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


--Copiamos los datos del csv a la tabla definitiva

\COPY BIRTHS(state, state_abbreviation, year, gender, mother_education_level, education_level_code, births, mother_average_age, average_birth_weight) FROM 'us_births_2016_2021.csv' DELIMITER ',' CSV HEADER;
select * from BIRTHS;
SELECT * FROM estado;
SELECT * FROM anio;
SELECT * FROM nivel_educacion;


--Funcion ReporteConsolidado(n)

CREATE OR REPLACE FUNCTION ReporteConsolidado(cantidad_de_anios INT) RETURNS VOID RETURNS NULL ON NULL INPUT AS $$
    DECLARE
		current_year anio.anio%TYPE;
		max_year anio.anio%TYPE;
		year TEXT;

		Total INT;
        AvgAge FLOAT;
		MinAge FLOAT;
		MaxAge FLOAT;
		AvgWeight FLOAT;
		MinWeight FLOAT;
		MaxWeight FLOAT;

		r_anio RECORD;
		r_state RECORD;
		r_gender RECORD;
		r_education_level RECORD;

	--cursor que devuelve resultados por Estado
	c_State CURSOR (anioIn INT) FOR
	       SELECT nombre, SUM(births) AS Total,  AVG(mother_average_age) AS AvgAge, MIN(mother_average_age) AS MinAge, MAX(mother_average_age) AS MaxAge, CAST( (AVG(average_birth_weight) / 1000 ) AS DECIMAL(5, 3)) AS AvgWeight, CAST( (MIN(average_birth_weight) / 1000) AS DECIMAL(5, 3)) AS MinWeight, CAST( (MAX(average_birth_weight) / 1000) AS DECIMAL(5, 3)) AS MaxWeight
	       FROM BIRTHS JOIN ESTADO ON BIRTHS.state_abbreviation = ESTADO.id
	       WHERE anioIn = BIRTHS.year
	       GROUP BY nombre
	       HAVING SUM(births) >= 200000
	       ORDER BY nombre DESC ;

	--cursor que devuelve resultados por Genero
	c_Gender CURSOR (anioIn INT) FOR
	       SELECT CASE WHEN gender = 'M' THEN 'Male' WHEN gender = 'F' THEN 'Female' END AS gender, SUM(births) AS Total, AVG(mother_average_age) AS AvgAge, MIN(mother_average_age) AS MinAge, MAX(mother_average_age) AS MaxAge, CAST( (AVG(average_birth_weight) / 1000 ) AS DECIMAL(5, 3)) AS AvgWeight, CAST( (MIN(average_birth_weight) / 1000) AS DECIMAL(5, 3)) AS MinWeight, CAST( (MAX(average_birth_weight) / 1000) AS DECIMAL(5, 3)) AS MaxWeight
	       FROM BIRTHS
	       WHERE 2016 = BIRTHS.year
	       GROUP BY gender
	       ORDER BY gender DESC;

	--cursor que devuelve resultados por Educacion
	c_Education CURSOR (anioIn INT) FOR
	   SELECT descripcion, SUM(births) AS Total, AVG(mother_average_age) AS AvgAge, MIN(mother_average_age) AS MinAge, MAX(mother_average_age) AS MaxAge, CAST( (AVG(average_birth_weight) / 1000 ) AS DECIMAL(5, 3)) AS AvgWeight, CAST( (MIN(average_birth_weight) / 1000) AS DECIMAL(5, 3)) AS MinWeight, CAST( (MAX(average_birth_weight) / 1000) AS DECIMAL(5, 3)) AS MaxWeight
	   FROM BIRTHS JOIN NIVEL_EDUCACION ON BIRTHS.education_level_code = NIVEL_EDUCACION.nivel
	   WHERE anioIn = BIRTHS.year AND descripcion != 'Unknown or Not Stated'
	   GROUP BY descripcion
	   ORDER BY descripcion DESC;

	--cursor que devuelve resultados por Año
	c_Anio CURSOR(anioIn INT) FOR
	   SELECT anio, SUM(births) AS Total, AVG(mother_average_age) AS AvgAge, MIN(mother_average_age) AS MinAge, MAX(mother_average_age) AS MaxAge, CAST( (AVG(average_birth_weight) / 1000 ) AS DECIMAL(5, 3)) AS AvgWeight, CAST( (MIN(average_birth_weight) / 1000) AS DECIMAL(5, 3)) AS MinWeight, CAST( (MAX(average_birth_weight) / 1000) AS DECIMAL(5, 3)) AS MaxWeight
	   FROM BIRTHS JOIN anio ON BIRTHS.year = anio.anio
	   WHERE anioIn = BIRTHS.year
	   GROUP BY anio
	   ORDER BY anio;


    BEGIN
		IF (cantidad_de_anios <= 0) THEN
            RETURN;
        END IF;

        SELECT MIN(anio) FROM anio INTO current_year;

		IF (current_year IS NULL) THEN
			RAISE EXCEPTION 'No hay valores ingresados';
		END IF;

        max_year = current_year + cantidad_de_anios - 1;

		IF (cantidad_de_anios > 0) THEN
            IF max_year > (SELECT MAX(anio) FROM anio)
	        THEN SELECT MAX(anio) FROM anio INTO max_year;
	    END IF;

    	RAISE NOTICE '------------------------------------------------------------------------------';
	    RAISE NOTICE '---------------------------CONSOLIDATED BIRTH REPORT--------------------------';
	    RAISE NOTICE '------------------------------------------------------------------------------';
	    RAISE NOTICE 'Year---Category---------------------------------------------------------Total-------AvgAge-------MinAge-------MaxAge-------AvgWeight-------MinWeight-------MaxWeight';

            WHILE (current_year <= max_year) LOOP
                year := current_year;
                total := 0;
				avgAge := 0;
				minAge := 0;
				maxAge := 0;
				avgWeight := 0;
				minWeight := 0;
				maxWeight := 0;


	        	RAISE NOTICE '--------------------------------------------------------------------------';

				OPEN c_State(anioIn := current_year);
					LOOP
						FETCH c_State INTO r_state;
						EXIT WHEN NOT FOUND;
						RAISE NOTICE '%   State:	    %														%		%		%		%		%		%		%', year, r_state.nombre::TEXT, r_state.total::INT, r_state.avgAge::INT, r_state.minAge::INT, r_state.maxAge::INT, r_state.avgWeight::FLOAT, r_state.minWeight::FLOAT, r_state.maxWeight::FLOAT;
						year := '----';
					END LOOP;
				CLOSE c_State;

				OPEN c_Gender(anioIn := current_year);
					LOOP
						FETCH c_Gender INTO r_gender;
						EXIT WHEN NOT FOUND;
						RAISE NOTICE '%   Gender:		%														%		%		%		%		%		%		%', year, r_gender.gender::TEXT, r_gender.total::INT, r_gender.avgAge::INT, r_gender.minAge::INT, r_gender.maxAge::INT, r_gender.avgWeight::FLOAT, r_gender.minWeight::FLOAT, r_gender.maxWeight::FLOAT;
					END LOOP;
				CLOSE c_Gender;

                OPEN c_Education(anioIn := current_year);
					LOOP
						FETCH c_Education INTO r_education_level;
						EXIT WHEN NOT FOUND;
						RAISE NOTICE '%   Education:	%														%		%		%		%		%		%		%', year, r_education_level.descripcion::TEXT, r_education_level.total::INT, r_education_level.avgAge::INT, r_education_level.minAge::INT, r_education_level.maxAge::FLOAT, r_education_level.avgWeight::FLOAT, r_education_level.minWeight::FLOAT, r_education_level.maxWeight::FLOAT;
					END LOOP;
				CLOSE c_Education;


				-- Se ejecuta el cursor Anio
				OPEN c_Anio(anioIn := current_year);
					LOOP
						FETCH c_Anio INTO r_anio;
						EXIT WHEN NOT FOUND;
						RAISE NOTICE '------------------------------------------------------------------------- %		%		%		%		%		%		%', r_anio.total::INT, r_anio.avgAge::INT, r_anio.minAge::INT, r_anio.maxAge::INT, r_anio.avgWeight::FLOAT, r_anio.minWeight::FLOAT, r_anio.maxWeight::FLOAT;
					END LOOP;
				CLOSE c_Anio;

				-- Se incrementa el anio seleccionado en una unidad
				current_year = current_year + 1;

			-- Salir del While
			END LOOP;

		-- Salir del IF
		END IF;
	END;
$$ LANGUAGE plpgSQL;

--Para testear
SELECT ReporteConsolidado(1);
SELECT ReporteConsolidado(0);
SELECT ReporteConsolidado(2);
SELECT ReporteConsolidado(-1);