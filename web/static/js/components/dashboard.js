import { connect } from 'react-redux';
import React, { PropTypes } from 'react';
import {mapStateToProps} from '../reducers'
import Auth from './auth'

const mapDispatchToProps = (dispatch) => {
  return {
  };
};

const Dashboard = ({state, config}) => {
  if (state.configured == false) {
    return <Auth />
  }

  let connection_state = undefined
  if (state.connected) {
    connection_state = <span className="alert alert-success">Connected</span>
  } else {
    connection_state = <span className="alert alert-warning">Connecting</span>
  }

  return (
    <div className="container">
      <h1> Domoio Orbiter</h1>
      {connection_state}
    </div>
  )
};


Dashboard.propTypes = {
  config: PropTypes.object.isRequired,
  state: PropTypes.object.isRequired
};

const DashboardComponent = connect(
  mapStateToProps,
  mapDispatchToProps
)(Dashboard);

export default DashboardComponent;
