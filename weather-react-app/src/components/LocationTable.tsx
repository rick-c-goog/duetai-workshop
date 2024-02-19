import React from 'react';
import { WeatherLocation } from '../models/Weather';

interface LocationTableProps {
  locations: WeatherLocation[];
  currentLocation: WeatherLocation | null;
  onSelect: (location: WeatherLocation) => void;
}

const LocationTable: React.FC<LocationTableProps> = ({
  locations,
  currentLocation,
  onSelect,
}) => {
  return (
    <table className="table table-hover">
      <thead>
        <tr>
          <th>Name</th>
        </tr>
      </thead>
      <tbody>
       {locations.map(location =>
        <tr key={location.id}
            className={currentLocation?.id === location.id ? 'table-primary' : ''}
            onClick={() => onSelect(location)}>
          <td>{location.name}</td>
        </tr>
      )}
      </tbody>
    </table>
  );
};

export default LocationTable;

