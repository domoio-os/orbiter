import React from 'react'
import Auth from './auth'
import Dashboard from './dashboard'
import {mapStateToProps} from '../reducers'

export default {
  route: (store) => {
    let {state, config} = mapStateToProps(store)

    if (!state.configured) {
      return <Auth />
    }

    if (true) {
      return <Dashboard />
    }
    return null
  }
}
