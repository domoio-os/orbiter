import React from 'react'
import ReactDOM from 'react-dom'
import {Provider} from 'react-redux'
import {buildStore, dispatch} from './reducers'
import Dashboard from './components/dashboard'

let store = buildStore()


/*
 * Setup React Dom
 * -------------------------------------------------------------------*/

ReactDOM.render(
  <Provider store={store}><Dashboard /></Provider>
    ,document.getElementById('app')
);


/*
 * Fetch state
 * -------------------------------------------------------------------*/

fetch("/api/state")
  .then((resp) => {
    return resp.json()
  })
  .then((state) => {
    console.log(state)
    dispatch("SET_STATE", {state})
  })
