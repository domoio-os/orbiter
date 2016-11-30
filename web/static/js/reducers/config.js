// const filters = {};

// filters["SET_INITIAL_STATE"] = (state, action) => {
//   return List(action.data.components)
// };


// const ComponentsReducer = (state = List(), action) => {
//   if (action.type in filters) {
//     return filters[action.type](state, action);
//   } else {
//     return state;
//   }
// };

export default (reducer) => {

  reducer["SET_CONFIG"] = (state, action) => {
    console.log("Setting: ", action.config)
    state = state.set("config", action.config)
    return state
  }


}
