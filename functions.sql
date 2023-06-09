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


--funcion ReporteConsolidado(n)

CREATE OR REPLACE FUNCTION ReporteConsolidado(cantidad_de_anios INT) RETURNS VOID RETURNS NULL ON NULL INPUT AS $$
    BEGIN
		-- todo
	END;
$$ LANGUAGE plpgSQL;

