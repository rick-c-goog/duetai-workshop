import React, {FC} from "react";
import {Weather} from "../models/Weather";
import {getIconUrl} from "../services/WeatherService";
import {convertUnixTimeToDate} from "../services/TimeUtilities";

interface WeatherEntryProps {
    weather: Weather;
}

function convertToCelcius(inDegree: number) : String {
    return (inDegree-273.15).toFixed(1)
}
export const WeatherEntry: FC<WeatherEntryProps> = ({weather}) =>
    <div>
        <div>{convertUnixTimeToDate(weather.dt).toLocaleTimeString()}</div>
        <div>
            <strong>{convertToCelcius(weather.main.temp)}°C</strong>
            <div>({convertToCelcius(weather.main.temp_min)}°C / {convertToCelcius(weather.main.temp_max)}°C)</div>
        </div>
        <div>Humidity: {weather.main.humidity}%</div>
        {weather.weather.map(condition =>
            <div key={condition.id}>
                <img src={getIconUrl(condition.icon)} alt={condition.main}/> {condition.main} {condition.description}
            </div>)
        }
    </div>;