import { connect } from 'react-redux';
import React, { PropTypes } from 'react';
import {mapStateToProps} from '../reducers'

const mapDispatchToProps = (dispatch) => {
  return {
  };
};

const Dashboard = ({components, devices}) => (
  <div>
    <h1> Domoio Orbiter</h1>
  </div>
);


Dashboard.propTypes = {
  config: PropTypes.object.isRequired
};

const DashboardComponent = connect(
  mapStateToProps,
  mapDispatchToProps
)(Dashboard);

export default DashboardComponent;
