import { WeatherLocation, Weather } from '../models/Weather';
const key = process.env.REACT_APP_OPEN_WEATHER_API_KEY;
const keyQuery = `appid=${key}`;
const server = 'https://api.openweathermap.org/data/2.5';

export async function searchLocation(term: string): Promise<WeatherLocation | undefined> {
  const uri= `${server}/weather?q=${term}&${keyQuery}`;
  console.log(uri);
  const result = await fetch(`${server}/weather?q=${term}&${keyQuery}`);

  if (result.status === 404) return undefined;
  if (result.status !== 200) throw new Error('Failed to read location data');

  return await result.json();
}

export async function readWeather(locationId: number): Promise<Weather> {
  const result = await fetch(`${server}/weather?id=${locationId}&${keyQuery}`);

  if (result.status !== 200) throw new Error('Failed to read weather data');

  return await result.json();
}

export function getIconUrl(code: string): string {
  return `http://openweathermap.org/img/wn/${code}@2x.png`;
}
