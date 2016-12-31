import React from 'react'
import Auth from './auth'
import Dashboard from './dashboard'
import {mapStateToProps} from '../reducers'

export default {
  route: (store) => {
    let {state, config} = mapStateToProps(store)
    console.log(state)

    if (state.configured == false) {
      console.log("auth", state.configured)
      return <Auth />
    }

    console.log("dash", state.configured)
    return <Dashboard />
  }
}
