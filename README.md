# Weatherman 
is a simple tool build on top of [nager.at holiday API](https://date.nager.at/Api "nager.at") and the [open-meteo](https://open-meteo.com/ "open-meteo") API.

It allows you to define a location with lat and long coordinates for which it will get a weather forecast for the next 24 hours from **open-meteo**. It then queries **nager.at** if the respective day is a holiday in Spain (presently not configurable), so all day is considered superOffPeak.

Prices will now be ranked by temperature, so you can get the highest outside temperature in the best energy price window, ideal for **heat pump** applications.

The number of time slots is configurable in the request.

Work in progress.


# Run your own
### Prerequisites
- docker-compose

### Configure
- adapt environment in **docker-compose.yaml** accordingly or create a **docker-compose.override.yaml** file
- **do not change TZ**
- **API_SECRET** is required by default. Incoming queries to the REST server need to provide this as **API_KEY** in the request header.

### Setup
- execute `./deploy.sh`
- Default port is 3002. **Congratulations**. You now have a running weatherman on this port. 
It can easily be reverse proxied if need be.

### Updating
- executing `./deploy.sh `will always rebuild the main branch of this repository and restart the container