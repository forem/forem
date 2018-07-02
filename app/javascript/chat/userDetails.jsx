

import { h, Component } from 'preact';

export default class UserDetails extends Component {
  render() {
    const user = this.props.user
    return <div><img
                    src={user.profile_image}
                    style={{height: "210px",
                      width: "210px",
                      margin:" 15px auto",
                      display: "block",
                      borderRadius: "500px"}} />
                <h1 style={{textAlign: "center"}}>
                  <a href={"/"+user.username}>{user.name}</a>
                </h1>
                <div style={{fontStyle: "italic"}}>
                  {user.summary}
                </div>
             </div>
  }

}