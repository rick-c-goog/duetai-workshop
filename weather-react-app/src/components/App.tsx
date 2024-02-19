import React, { FC, useState } from 'react';
import './App.css';
import LocationSearch from './LocationSearch';
import LocationTable from './LocationTable';
import { WeatherLocation } from '../models/Weather';
import { searchLocation } from '../services/WeatherService';
import WeatherSummary from './WeatherSummary';

const App: FC = () => {
  const [locations, setLocations] = useState<WeatherLocation[]>([]);
  const [currentLocation, setCurrentLocation] = useState<WeatherLocation | null>(null);

  let addLocation = async (term: string) => {
    const location = await searchLocation(term);
    if (!location) {
      console.log(`No location found called '${term}'`);
    } else {
      setLocations([location, ...locations]);
      setCurrentLocation(location);
    }
  };

  return (
    <div className="container">
      <h1>Weather App</h1>
      <div className="row">
        <div className="col-md-6">
          <LocationSearch onSearch={addLocation} />
        </div>
        <div className="col-md-6">
          <h2>Location</h2>
          <LocationTable
            locations={locations}
            currentLocation={currentLocation}
            onSelect={setCurrentLocation}
          />
        </div>
      </div>
      <div className="row">
        <div className="col-md-12">
        <WeatherSummary location={currentLocation}/>
        </div>
      </div>
    </div>
  );
};

export default App;


