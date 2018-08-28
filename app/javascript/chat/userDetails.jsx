

import { h, Component } from 'preact';
import twitterImage from 'images/twitter-logo.svg';
import githubImage from 'images/github-logo.svg';
import websiteImage from 'images/external-link-logo.svg';

export default class UserDetails extends Component {
  render() {
    const user = this.props.user
    let socialIcons = []
    if (user.twitter_username) {
      socialIcons.push(<a href={'https://twitter.com/'+user.twitter_username} target='_blank'><img src={twitterImage} style={{width: "30px", margin: "5px 15px 15px 0px"}} /></a>)
    }
    if (user.github_username) {
      socialIcons.push(<a href={'https://github.com/'+user.github_username} target='_blank'><img src={githubImage} style={{width: "30px", margin: "5px 15px 15px 0px"}} /></a>)
    }
    if (user.website_url) {
      socialIcons.push(<a href={user.website_url} target='_blank'><img src={websiteImage} style={{width: "30px", margin: "5px 15px 15px 0px"}} /></a>)
    }
    let userLocation = ''
    if (user.location && user.location.length > 0) {
      userLocation = <div>
                        <div class="key">
                          location
                        </div>
                        <div className="value">
                          {user.location}
                        </div>
                      </div>
}
    return <div><img
                    src={user.profile_image}
                    style={{height: "210px",
                      width: "210px",
                      margin:" 15px auto",
                      display: "block",
                      borderRadius: "500px"}} />
                <h1 style={{textAlign: "center"}}>
                  <a href={"/"+user.username} target='_blank'>{user.name}</a>
                </h1>
                <div style={{height: "50px", margin:"auto",width: "96%"}}>
                  {socialIcons}
                </div>
                <div style={{fontStyle: "italic"}}>
                  {user.summary}
                </div>
                <div className='activechatchannel__activecontentuserdetails'>
                  {userLocation}
                  <div class="key">
                    joined
                  </div>
                  <div className="value">
                    {user.joined_at}
                  </div>
                </div>
             </div>
  }

}