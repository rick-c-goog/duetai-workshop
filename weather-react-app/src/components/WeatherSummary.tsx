import React, { useEffect, useState } from 'react';
import { WeatherLocation, Weather } from '../models/Weather';
import { readWeather } from '../services/WeatherService';
import {WeatherEntry} from './WeatherEntry';


interface WeatherSummaryProps {
  location: WeatherLocation | null;
}
export const WeatherSummary: React.FC<WeatherSummaryProps> = ({location}) => {
  const [weather, setWeather] = useState<Weather | null>(null);

  useEffect(() => {
      if (location) {
          readWeather(location.id).then(weather => setWeather(weather));
      }
  }, [location]);

  if (!location || !weather) return null;

  return (
      <div>
          <hr/>
          <h2>{location.name}</h2>
          <WeatherEntry weather={weather}/>
      </div>
  );
};