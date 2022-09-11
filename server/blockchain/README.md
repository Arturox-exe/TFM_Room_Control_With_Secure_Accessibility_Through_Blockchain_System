
# Hyperledger farbric blockchain

Red fabric. La red esta diseñada para lanzarse con docker-compose.

# Instalación

Para lanzar la red debemos seguir los siguientes pasos:

1. Crear el material criptografico
    Para ello nos vamos a la carpeta network/channel y ejecutamos el script create-artifacts.sh
    Es importante ejecutar el comando desde la misma carpeta para crear los ficheros en la ruta adecuada
    Este script creara todo el material cryptografico en la carpeta network/channel/cryto-config

2. Levantar la red, crear el canal e instalar los chaincodes
    Para ello nos vamos a la carpeta raiz del proyecto y ejecutamos el script start.sh

3. Levantar el explorer
    Primero debemos copiar la carpeta cryto-config que esta en network/channel en el directorio raiz del
    explorer.
    Despues nos vamos a la carpeta "explorer" y ejecutamos el comando docker-compose up. Esto nos levantara un contenedor con una base de datos y otro con el api del dashboard en el puerto 8080.
    Las credenciales son:
        user: exploreradmin
        password: exploreradminpw
4. Levantar el api server
    Primero hay que instalar los paquetes necesarios ejecutando el comando "npm install"
    Despues nos vamos a carpeta api-2.0/config y ejecutamos el script "generate-ccp.sh". Con lo que se genera el fichero de conexion a la red.
    Despues, desde la carpeta api-2.0 lanzamos el comando nodemon app.js, lo que nos levantara el api server (hay que pasarlo a docker)
    
