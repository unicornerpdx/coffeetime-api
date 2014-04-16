## Application Interface

The application interface for the _Coffee Scoreboard_ is an opinionated
`JSON` based API.  The returning `Status Code` will always be `200`,
even in the case of errors, which will also be encoded as `JSON`.

### Versioning

The application interface for the _Coffee Scoreboard_ is versioned.  This
documentation covers _version 1_.

### Authentication

Authentication returns an `access_token` which must be used for all
other API requests.  The access token must be presented as an HTTP
`Authorization` header:

```
Authorization: Bearer yourtoken
```

### Parameters

Requests can be made by sending either `www-form-encoded` data, or JSON
data.  Just be sure to set the `Content-Type` header appropriately!

_Form Encoded_

```
POST /1/transaction/create HTTP/1.1
Host: coffeetime.io
Authorization: Bearer abc123
Content-Type: application/x-www-form-urlencoded

user_id=123&group_id=13&amount=3&note=Paying%20You%20Back&
latitude=45.5165&longitude=-122.6165&accuracy=100&
date=2014-04-04T09:43:00-0700
```

_JSON Encoded_

```
POST /1/transaction/create HTTP/1.1
Host: coffeetime.io
Authorization: Bearer abc123
Content-Type: application/json

{
  "user_id": 123,
  "group_id": 13,
  "amount": 3,
  "note": "Paying You Back",
  "latitude": 45.5165,
  "longitude": -122.6165,
  "accuracy": 100,
  "date": "2014-04-04T09:43:00-0700"
}
```

### Routes

#### POST /1/auth

Exchanges a GitHub authorization code for an access token and user
information.

_Parameters_

Parameter | Description
----------|------------
code      | GitHub auth token

_Returns_

An object containing the `access token` that is used for authentication,
and some user data about the authenticated user.

```js
{
    "access_token": "abc123",
    "user_id": 123,
    "username": "JohnSmith",
    "display_name": "John Smith",
    "avatar_url": "https://github.com/images/error/octocat_happy.gif"
}
```

#### POST /1/device/register

Registers a mobile device with the server, including keys for devices
messaging.

_Parameters_

Parameter | Description
----------|------------
uuid      | Unique identifier for the device
token     | Device token (ANPS, GCM)
token_type| String of apns_production, apns_sandbox, or gcm

_Returns_

An object showing success.

```js
{
  "status": "ok"
}
```

#### GET /1/group/list

Retrieves the list of groups the user tied to the access token is part of.

_Returns_

An object containing all of the groups the user is part of, as well as the
balance in each of those groups.

```js
{
  "groups": [
    {
      "group_name": "Special Place",
      "timezone": "America/Los_Angeles",
      "group_id": 123,
      "user_balance": 13,
      "min_balance": -10,
      "max_balance": 13
    },
    {
      "group_name": "Bad Place",
      "timezone": "America/Los_Angeles",
      "group_id": 124,
      "user_balance": -3,
      "min_balance": -10,
      "max_balance": 13
    }
  ]
}
```

#### GET /1/group/info

Retrieves the current balance within the group, all users in the group,
as well as the latest transactions up to 20.

_Parameters__

Parameter | Description
----------|------------
group_id  | Group ID to query for

_Returns_

An object containing users, balances, and transactions.

```js
{
  "group_name": "Special Place",
  "timezone": "America/Los_Angeles",
  "user_balance": 123,
  "min_balance": -100,
  "max_balance": 150,
  "users": [
    {
      "user_id": 13,
      "username": "JohnSmith",
      "display_name": "John Smith",
      "avatar_url": "https://github.com/images/error/octocat_happy.gif",
      "active": true
    }
  ],
  "transactions": [
    {
      "transaction_id": 200,
      "from_user_id": 13,
      "to_user_id": 14,
      "latitude": 45,
      "longitude": -122,
      "accuracy": 1000,
      "amount": 3,
      "note": "Sucker",
      "date": "2014-03-27T09:00:00-0700",
      "created_by": 13,
      "summary": "You bought Ryan 3 coffees"
    }
  ]
}
```

#### POST /1/transaction/create

Creates a transaction.

_Parameters_

Parameter | Description
----------|------------
user_id   | User you are in a transaction with
group_id  | Group you are interacting with
amount    | Positive or negative amount of debt in whole numbers
note      | Optional note
latitude  | Optional latitude
longitude | Optional longitude
accuracy  | Optional accuracy
location_date | Optional date the location was taken

_Returns_

Returns the same object as `/1/group/info`.

```js
{
  "group_name": "Special Place",
  "timezone": "America/Los_Angeles",
  "user_balance": 123,
  "min_balance": -100,
  "max_balance": 150,
  "users": [
    {
      "user_id": 13,
      "username": "JohnSmith",
      "display_name": "John Smith",
      "avatar_url": "https://github.com/images/error/octocat_happy.gif",
      "active": true
    }
  ],
  "transactions": [
    {
      "transaction_id": 200,
      "from_user_id": 13,
      "to_user_id": 14,
      "latitude": 45,
      "longitude": -122,
      "accuracy": 1000,
      "amount": 3,
      "note": "Sucker",
      "date": "2014-03-27T09:00:00-0700",
      "created_by": 13,
      "summary": "You bought Ryan 3 coffees"
    }
  ]
}
```

#### GET /1/user/info

Retrieves user information for a user.

_Parameters_

Parameter | Description
----------|------------
user_id   | Optional user id (defaults to authenticated user)
group_id  | Optional

_Returns_

Returns an object containing user information.  If a group_id is given,
balances and activity are returned as well.

```js
{
  "user_id": 13,
  "username": "JohnSmith",
  "display_name": "John Smith",
  "avatar_url": "https://github.com/images/error/octocat_happy.gif",
  "user_balance": 10,   // only if group_id was given
  "max_balance": 10,    // only if group_id was given
  "min_balance": -10,   // only if group_id was given
  "active": false       // only if group_id was given
} 
```

#### POST /1/group/create

Creates a CoffeeTime group from a GitHub organization and adds all users
with a zero balance.

_Parameters_

Parameter | Description
----------|------------
github_team_id | Organization ID from GitHub
name      | Name of the organization
timezone  | Optional Timezone (name) to be used for the organization

_Returns_

Returns an object containing the new group_id, group_name, and timezone.

```js
{       
  group_id: 1,      
  group_name: "Esri PDX",       
  timezone: "America/Los_Angeles"     
}
```

#### POST /1/group/update

Updates the list of members in the group from the GitHub organization.

_Parameters_

Parameter | Description
----------|------------
group_id  | Group ID to update
name      | Optional Name of the organization
timezone  | Optional Timezone (name) to be used for the organization

_Returns_

Returns an object containing the users added and removed as well as
current group information.

```js
{
  "group_id": 11,   
  "group_name": "Esri PDX",   
  "timezone": "America/Los_Angeles",   
  "users_added": [  /* basic user profile info like in user/info */  ],   
  "users_removed": [    ] 
}
```

#### GET /1/team/list

Lists all teams the authenticated user belongs to on GitHub.

_Returns_

Returns an object containing an array of all GitHub teams the user is part
of.

```js
{
  "teams": [
    "github_id": 30000,
    "name": "Coffee",
    "org": "esri",
    "members": 18
  ]
}
```

#### POST /1/callback/create

Creates a callback hook that is called any time a transaction is created.

_Parameters_

Parameter | Description
----------|------------
group_id  | Group ID to add a callback to
url       | URL of the Callback

_Returns_

```js
{
  "status": "ok"
}
```

#### GET /1/callback/list

Retrieves a list of callbacks and the last response.

_Parameters_

Parameter | Description
----------|------------
group_id  | Group ID to query

_Returns_

Returns an object containing a list of callbacks and their last status.

```js
{
  "callbacks": [
    {
      "url": "http://example.com/callback"
      "last_request_date": "2014-03-27T13:49:00-0700",
      "last_response_date": "2014-03-27T13:49:00-0700",
      "last_response_status": "ok",
      "last_response_status_code": 200
    }
  ]
}
```

#### GET /1/callback/status

Retrieves the last status for a specific callback.

_Parameters_

Parameter | Description
----------|------------
group_id  | Group ID to query
url       | Callback URL to query

_Returns_

Returns an object containing the callback and a detailed report of the
last status returned.

```js
{
  "url": "http://example.com/callback"
  "last_request_date": "2014-03-27T13:49:00-0700",
  "last_response_date": "2014-03-27T13:49:00-0700",
  "last_response_status": "ok",
  "last_response_status_code": 200,
  "request": "POST /callback HTTP/1.1\nHOST: example.com\n...."
  "response": "HTTP/1.1 200 OK"
}
```

#### POST /1/callback/remove

Removes a callback from the group.

_Parameters_

Parameter | Description
----------|------------
group_id  | Group ID to query
url       | Callback URL to remove

_Returns_

```js
{
  "status": "ok"
}
```
