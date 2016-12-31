import { connect } from 'react-redux';
import React, { PropTypes } from 'react';
import {mapStateToProps} from '../reducers'
import {domoioUrl} from "../network"

const mapDispatchToProps = (dispatch) => {
  return {

  };
};

let startOauth = () => {
  let redirect_uri = `${window.location.origin}/auth_reply`
  fetch("/api/auth_request")
    .then((resp) => resp.json())
    .then((data) => {
      let url = `${domoioUrl}/join?scope=orbiter&response_type=token&redirect_uri=${redirect_uri}&client_id=${data.hardware_id}&state=${data.public_key}`
      window.location = url
    })
}

const Auth = ({components, devices}) => (
  <div>
    <h1 className="page_header">Connect your device.</h1>
    <button onClick={() => startOauth()} className="btn btn-success btn-lg">Connect</button>
  </div>
);


Auth.propTypes = {
  config: PropTypes.object.isRequired
};

const AuthComponent = connect(
  mapStateToProps,
  mapDispatchToProps
)(Auth);

export default AuthComponent;
