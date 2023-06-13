# TPE-BD1

## Objetivo
El objetivo de este Trabajo Práctico Especial es aplicar los conceptos de SQL Avanzado (PSM,
Triggers) vistos a lo largo del curso, para implementar funcionalidades y restricciones no disponibles
de forma estándar (que no pueden resolverse con Primary Keys, Foreign Keys, etc.).

## Requisitos previos
Para poder ejecutar el programa, debe contar con los archivos us_births_2016_2021.csv brindado por la cátedra y el archivo funciones.sql.

## Ejecución
1. En una terminal, deben enviarse los archivos mencionados anteriormente a pampero utilizando el siguiente comando:
```bash
scp funciones.sql us_births_2016_2021.csv {user}@pampero.itba.edu.ar:/home/{user}/
```
2. Luego, en otra terminal, conectarse a pampero (al servidor de la BD de la catedra) utilizando el siguiente comando:
```bash
ssh user@pampero.itba.edu.ar -L 5440:bd1.it.itba.edu.ar:5432
```
3. Una vez conectado, debe crear las tablas, los triggers y las funciones en la base de datos utilizando el siguiente comando:
```bash
psql -h bd1.it.itba.edu.ar -U {user} -f funciones.sql PROOF
```
4. Por último, debe conectarse a la DB de itba utilizando el siguiente comando:
```bash
psql -h bd1.it.itba.edu.ar -U {user} PROOF
```
El programa se encuentra ahora listo para ser usado, puede probar las funcionalidades ejecutando las siguientes funciones:
```bash
SELECT ReporteConsolidado(1);
SELECT ReporteConsolidado(0);
SELECT ReporteConsolidado(2);
SELECT ReporteConsolidado(-1);
```