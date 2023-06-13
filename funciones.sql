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

CREATE TABLE NACIMIENTOS (
	idEstado VARCHAR(30),
	idEducacion VARCHAR(10),
	idAnio INT,
	genero CHAR(1),
	nacimientos INT,
	edad_promedio FLOAT,
	peso_promedio FLOAT,

	PRIMARY KEY(idEstado, idAnio, idEducacion, genero),
	FOREIGN KEY (idEstado) REFERENCES ESTADO,
	FOREIGN KEY (idAnio) REFERENCES ANIO,
	FOREIGN KEY (idEducacion) REFERENCES NIVEL_EDUCACION
);

-- Tabla temporal para copiar todos los datos del csv

CREATE TEMPORARY TABLE TABLA_TEMPORAL_NACIMIENTOS
(
    state VARCHAR(30),
	state_abbreviation VARCHAR(10),
	year INT,
	gender CHAR(1),
	mother_education_level VARCHAR(100),
	education_level_code VARCHAR(10),
	births INT,
	mother_average_age FLOAT,
	average_birth_weight FLOAT
);

-- Funcion para saber si es año bisiesto

CREATE OR REPLACE FUNCTION esBisiesto(anio INT) RETURNS BOOLEAN AS $$
	BEGIN
		RETURN anio % 4 = 0 AND (anio % 100 != 0 OR anio % 400 = 0);
	END;
$$ LANGUAGE plpgSQL;

-- Trigger

CREATE OR REPLACE FUNCTION insertarDatos() RETURNS trigger AS $$
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

	    INSERT INTO NACIMIENTOS VALUES (id_estado, id_nivel_educacion, id_anio, new.gender, new.births, new.mother_average_age , new.average_birth_weight);

	    new.state := id_estado;
	    new.year := id_anio;
	    new.mother_education_level := id_nivel_educacion;

        return new;

	END;

$$ LANGUAGE plpgSQL;

CREATE TRIGGER insertarDatos
BEFORE INSERT ON TABLA_TEMPORAL_NACIMIENTOS
FOR EACH ROW
EXECUTE PROCEDURE insertarDatos();


-- Copiamos los datos del csv a la tabla auxiliar

\COPY TABLA_TEMPORAL_NACIMIENTOS(state, state_abbreviation, year, gender, mother_education_level, education_level_code, births, mother_average_age, average_birth_weight) FROM 'us_births_2016_2021.csv' DELIMITER ',' CSV HEADER;

-- Funcion ReporteConsolidado(n)

CREATE OR REPLACE FUNCTION ReporteConsolidado(cantidad_de_anios INT) RETURNS VOID RETURNS NULL ON NULL INPUT AS $$
    DECLARE
		current_year anio.anio%TYPE;
		max_year anio.anio%TYPE;
		year TEXT;

		Total INT;
        AvgAge INT;
		MinAge INT;
		MaxAge INT;
		AvgWeight FLOAT;
		MinWeight FLOAT;
		MaxWeight FLOAT;

		r_anio RECORD;
		r_state RECORD;
		r_gender RECORD;
		r_education_level RECORD;

	-- Cursor que devuelve resultados por Estado

	c_State CURSOR (anioIn INT) FOR
	       SELECT nombre, SUM(NACIMIENTOS.nacimientos) AS Total,  AVG(edad_promedio) AS AvgAge, MIN(edad_promedio) AS MinAge, MAX(edad_promedio) AS MaxAge, CAST( (AVG(peso_promedio) / 1000 ) AS DECIMAL(5, 3)) AS AvgWeight, CAST( (MIN(peso_promedio) / 1000) AS DECIMAL(5, 3)) AS MinWeight, CAST( (MAX(peso_promedio) / 1000) AS DECIMAL(5, 3)) AS MaxWeight
	       FROM NACIMIENTOS JOIN ESTADO ON NACIMIENTOS.idEstado = ESTADO.id
	       WHERE anioIn = NACIMIENTOS.idAnio
	       GROUP BY nombre
	       HAVING SUM(NACIMIENTOS.nacimientos) >= 200000
	       ORDER BY nombre DESC ;

	-- Cursor que devuelve resultados por Genero

	c_Gender CURSOR (anioIn INT) FOR
	       SELECT CASE WHEN genero = 'M' THEN 'Male' WHEN genero = 'F' THEN 'Female' END AS gender, SUM(NACIMIENTOS.nacimientos) AS Total,  AVG(edad_promedio) AS AvgAge, MIN(edad_promedio) AS MinAge, MAX(edad_promedio) AS MaxAge, CAST( (AVG(peso_promedio) / 1000 ) AS DECIMAL(5, 3)) AS AvgWeight, CAST( (MIN(peso_promedio) / 1000) AS DECIMAL(5, 3)) AS MinWeight, CAST( (MAX(peso_promedio) / 1000) AS DECIMAL(5, 3)) AS MaxWeight
	       FROM NACIMIENTOS
	       WHERE anioIn = NACIMIENTOS.idAnio
	       GROUP BY gender
	       ORDER BY gender DESC;

	-- Cursor que devuelve resultados por Educacion

	c_Education CURSOR (anioIn INT) FOR
	   SELECT descripcion, SUM(NACIMIENTOS.nacimientos) AS Total,  AVG(edad_promedio) AS AvgAge, MIN(edad_promedio) AS MinAge, MAX(edad_promedio) AS MaxAge, CAST( (AVG(peso_promedio) / 1000 ) AS DECIMAL(5, 3)) AS AvgWeight, CAST( (MIN(peso_promedio) / 1000) AS DECIMAL(5, 3)) AS MinWeight, CAST( (MAX(peso_promedio) / 1000) AS DECIMAL(5, 3)) AS MaxWeight
	   FROM NACIMIENTOS JOIN NIVEL_EDUCACION ON NACIMIENTOS.idEducacion = NIVEL_EDUCACION.nivel
	   WHERE anioIn = NACIMIENTOS.idAnio AND descripcion != 'Unknown or Not Stated'
	   GROUP BY descripcion
	   ORDER BY descripcion DESC;

	-- Cursor que devuelve resultados por Año

	c_Anio CURSOR(anioIn INT) FOR
	   SELECT anio, SUM(NACIMIENTOS.nacimientos) AS Total,  AVG(edad_promedio) AS AvgAge, MIN(edad_promedio) AS MinAge, MAX(edad_promedio) AS MaxAge, CAST( (AVG(peso_promedio) / 1000 ) AS DECIMAL(5, 3)) AS AvgWeight, CAST( (MIN(peso_promedio) / 1000) AS DECIMAL(5, 3)) AS MinWeight, CAST( (MAX(peso_promedio) / 1000) AS DECIMAL(5, 3)) AS MaxWeight
	   FROM NACIMIENTOS JOIN anio ON NACIMIENTOS.idAnio = anio.anio
	   WHERE anioIn = NACIMIENTOS.idAnio
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

    	RAISE NOTICE '---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------';
	    RAISE NOTICE '-------------------------------------------------------------------------------------CONSOLIDATED BIRTH REPORT-------------------------------------------------------------------------------------';
	    RAISE NOTICE '---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------';
	    RAISE NOTICE 'Year---Category-----------------------------------------------------------------------------------------------------Total-------AvgAge----MinAge----MaxAge----AvgWeight----MinWeight----MaxWeight--';

            WHILE (current_year <= max_year) LOOP
                year := current_year;
                total := 0;
				avgAge := 0;
				minAge := 0;
				maxAge := 0;
				avgWeight := 0;
				minWeight := 0;
				maxWeight := 0;

				OPEN c_State(anioIn := current_year);
					LOOP
						FETCH c_State INTO r_state;
						EXIT WHEN NOT FOUND;
						RAISE NOTICE '%   State:	   % % %        %        % % % %', year, RPAD(r_state.nombre::TEXT, 97), RPAD(r_state.total::TEXT, 13), r_state.avgAge::INT, r_state.minAge::INT, r_state.maxAge::INT, LPAD(r_state.avgWeight::TEXT, 12), LPAD(r_state.minWeight::TEXT, 12), LPAD(r_state.maxWeight::TEXT, 12);
						year := '----';
					END LOOP;
				CLOSE c_State;

				OPEN c_Gender(anioIn := current_year);
					LOOP
						FETCH c_Gender INTO r_gender;
						EXIT WHEN NOT FOUND;
						RAISE NOTICE '%   Gender:	   % % %        %        % % % %', year, RPAD(r_gender.gender::TEXT, 97), RPAD(r_gender.total::TEXT, 13), r_gender.avgAge::INT, r_gender.minAge::INT, r_gender.maxAge::INT, LPAD(r_gender.avgWeight::TEXT, 12), LPAD(r_gender.minWeight::TEXT, 12), LPAD(r_gender.maxWeight::TEXT, 12);
					END LOOP;
				CLOSE c_Gender;

                OPEN c_Education(anioIn := current_year);
					LOOP
						FETCH c_Education INTO r_education_level;
						EXIT WHEN NOT FOUND;
						RAISE NOTICE '%   Education: % % %        %        % % % %', year, RPAD(r_education_level.descripcion::TEXT, 97), RPAD(r_education_level.total::TEXT, 13), r_education_level.avgAge::INT, r_education_level.minAge::INT, r_education_level.maxAge::INT, LPAD(r_education_level.avgWeight::TEXT, 12), LPAD(r_education_level.minWeight::TEXT, 12), LPAD(r_education_level.maxWeight::TEXT, 12);
					END LOOP;
				CLOSE c_Education;


				-- Se ejecuta el cursor Anio
				OPEN c_Anio(anioIn := current_year);
					LOOP
						FETCH c_Anio INTO r_anio;
						EXIT WHEN NOT FOUND;
						RAISE NOTICE '------------------------------------------------------------------------------------------------------------------- %       %        %        % % % %', r_anio.total::TEXT, r_anio.avgAge::INT, r_anio.minAge::INT, r_anio.maxAge::INT, LPAD(r_anio.avgWeight::TEXT, 12), LPAD(r_anio.minWeight::TEXT, 12), LPAD(r_anio.maxWeight::TEXT, 12);
						RAISE NOTICE '---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------';
					END LOOP;
				CLOSE c_Anio;

				-- Se incrementa el anio seleccionado en una unidad
				current_year = current_year + 1;

			END LOOP;

		END IF;
	END;
$$ LANGUAGE plpgSQL;
