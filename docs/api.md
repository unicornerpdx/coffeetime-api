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
