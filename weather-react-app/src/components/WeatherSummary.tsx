import React, { useEffect, useState } from 'react';
import { WeatherLocation, Weather } from '../models/Weather';
import { readWeather } from '../services/WeatherService';
import {WeatherEntry} from './WeatherEntry';


interface WeatherSummaryProps {
  location: WeatherLocation | null;
}

const WeatherSummary: React.FC<WeatherSummaryProps> = ({ location }) => {
  const [weather, setWeather] = useState<Weather | null>(null);
  if(location === null) return null;
  console.log(location)
  useEffect(() => {

    readWeather(location.id).then((weather) => {
      setWeather(weather);
    });
  }, [location]);
  if (!location || !weather) return null;
  return (
    <div>
      {weather && (
        <div>
          <h1>{location.name}</h1>
          <WeatherEntry weather={weather}/>
        </div>
      )}
    </div>
  );
};

export default WeatherSummary;
