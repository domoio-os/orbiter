import { createStore, combineReducers } from 'redux';
import {Map} from "immutable"
import ConfigReducer from './config'
import StateReducer from './state'

export const dispatch = (type, meta) => {
  let action = Object.assign({}, meta, {type: type})
  return STORE.dispatch(action)
}

export const buildStore = () =>{
  STORE = createStore(rootReducer)
  return STORE
}

const buildReducers = (reducer, defaultState, reducers={}) => {
  reducer(reducers)
  return (state = defaultState, action) => {
    if (action.type in reducers) {
      return reducers[action.type](state, action);
    } else {
      return state
    }
  }
}

export const mapStateToProps = (store) => {
  return {
    config: store.config.toJS(),
    state: store.state.toJS()
  };
};

var STORE = undefined
var rootReducer = combineReducers({
  config: buildReducers(ConfigReducer, Map()),
  state: buildReducers(StateReducer, Map({connected: false, configured: false}))
})
