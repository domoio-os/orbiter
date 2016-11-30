import {Map} from "immutable"

export default (reducer) => {

  reducer["SET_STATE"] = (state, action) => {
    return Map(action.state)
  }
}
