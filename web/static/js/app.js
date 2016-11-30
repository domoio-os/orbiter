import React from 'react'
import ReactDOM from 'react-dom'
import {Provider} from 'react-redux'
import {buildStore, dispatch} from './reducers'
import Navigator from './components/navigator'

let store = buildStore()


/*
 * Setup React Dom
 * -------------------------------------------------------------------*/

ReactDOM.render(
  <Provider store={store}>{Navigator.route(store.getState())}</Provider>
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
    dispatch("SET_STATE", {state})
  })
