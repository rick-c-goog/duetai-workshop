import React, { FC, useState } from 'react';
import { searchLocation} from '../services/WeatherService';

interface LocationSearchProps {
  onAddLocation: (location: string) => void;
}

export const LocationSearch: FC<LocationSearchProps> = ({onAddLocation}) => {
  const [locationSearch, setLocationSearch] = useState('');

  const disableSearch = locationSearch.trim() === '';

  const handleAddLocation = async () => {
    const location = await searchLocation(locationSearch);
    onAddLocation(locationSearch);
    setLocationSearch('');
  };

  return (
    <div>
      <label>Add location:</label>
      <input type="text" value={locationSearch} onChange={(e) => setLocationSearch(e.target.value)} />
      <button disabled={disableSearch} className="btn btn-primary" onClick={handleAddLocation}>
        Search
      </button>
    </div>
  );
};

export default LocationSearch;
