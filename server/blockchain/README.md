
# Hyperledger farbric blockchain

Red fabric. La red esta diseñada para lanzarse con docker-compose.

# Instalación

Para lanzar la red debemos seguir los siguientes pasos:

1. Crear el material criptografico
    Para ello nos vamos a la carpeta network/channel y ejecutamos el script create-artifacts.sh
    Es importante ejecutar el comando desde la misma carpeta para crear los ficheros en la ruta adecuada
    Este script creara todo el material cryptografico en la carpeta network/channel/cryto-config

2. Levantar el api server
    Nos vamos a carpeta api-2.0/config y ejecutamos el script "generate-ccp.sh". Con lo que se genera el fichero de conexion a la red.
    Despues, desde la carpeta api-2.0 lanzamos el comando docker build . api.tfm, lo que que crearña la imagen docker del api rest.
    
3. Levantar la red, crear el canal e instalar los chaincodes
    Para ello nos vamos a la carpeta raiz del proyecto y ejecutamos el script start.sh
    
    
