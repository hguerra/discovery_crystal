# Casdoor API Integration Guide - Complete Reference for LLMs

## Overview

Casdoor is a UI-first Identity Access Management (IAM) / Single-Sign-On (SSO) platform that provides comprehensive authentication and authorization services. This document provides a complete reference for integrating with Casdoor via REST APIs, optimized for LLM processing and code generation.

## Table of Contents

1. [Authentication & Authorization](#authentication--authorization)
2. [User Management APIs](#user-management-apis)
3. [Application Management APIs](#application-management-apis)
4. [Organization Management APIs](#organization-management-apis)
5. [Role & Permission APIs](#role--permission-apis)
6. [Provider Management APIs](#provider-management-apis)
7. [Session & Token Management](#session--token-management)
8. [Audit & Logging APIs](#audit--logging-apis)
9. [Integration Patterns](#integration-patterns)
10. [Error Handling](#error-handling)
11. [Security Best Practices](#security-best-practices)

---

## Authentication & Authorization

### OAuth 2.0 / OpenID Connect Flow

#### 1. Authorization Code Flow

```http
GET /login/oauth/authorize
```

**Parameters:**
- `client_id` (required): Application client ID
- `response_type` (required): Must be "code"
- `redirect_uri` (required): Callback URL
- `scope` (optional): Space-separated scopes (e.g., "openid profile email")
- `state` (optional): CSRF protection token
- `prompt` (optional): "login", "consent", "none"

**Example Request:**
```bash
curl -X GET "https://casdoor.example.com/login/oauth/authorize?client_id=your_client_id&response_type=code&redirect_uri=https://your-app.com/callback&scope=openid%20profile%20email&state=random_state_token"
```

#### 2. Token Exchange

```http
POST /api/login/oauth/access_token
Content-Type: application/json
```

**Request Body:**
```json
{
  "grant_type": "authorization_code",
  "client_id": "your_client_id",
  "client_secret": "your_client_secret",
  "code": "authorization_code",
  "redirect_uri": "https://your-app.com/callback"
}
```

**Response:**
```json
{
  "access_token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
  "refresh_token": "refresh_token_here",
  "expires_in": 3600,
  "token_type": "Bearer",
  "scope": "openid profile email"
}
```

#### 3. Refresh Token

```http
POST /api/login/oauth/access_token
Content-Type: application/json
```

**Request Body:**
```json
{
  "grant_type": "refresh_token",
  "client_id": "your_client_id",
  "client_secret": "your_client_secret",
  "refresh_token": "refresh_token_here"
}
```

#### 4. User Info Endpoint

```http
GET /api/get-user
Authorization: Bearer {access_token}
```

**Response:**
```json
{
  "owner": "built-in",
  "name": "user123",
  "createdTime": "2023-01-01T00:00:00Z",
  "updatedTime": "2023-01-01T00:00:00Z",
  "id": "user123",
  "type": "normal-user",
  "password": "",
  "passwordSalt": "",
  "displayName": "John Doe",
  "firstName": "John",
  "lastName": "Doe",
  "avatar": "https://example.com/avatar.jpg",
  "email": "john@example.com",
  "phone": "+1234567890",
  "address": ["123 Main St", "City", "State", "12345"],
  "affiliation": "Organization",
  "tag": "tag1",
  "score": 100,
  "isAdmin": false,
  "isGlobalAdmin": false,
  "isForbidden": false,
  "signupApplication": "app-built-in",
  "properties": {
    "key1": "value1",
    "key2": "value2"
  },
  "roles": ["role1", "role2"],
  "permissions": ["permission1", "permission2"]
}
```

### JWT Token Validation

#### 1. Introspect Token

```http
POST /api/get-user
Authorization: Bearer {access_token}
```

#### 2. Decode JWT Claims

```json
{
  "iss": "https://casdoor.example.com",
  "sub": "user123",
  "aud": "your_client_id",
  "exp": 1672531200,
  "iat": 1672527600,
  "scope": "openid profile email",
  "name": "John Doe",
  "email": "john@example.com",
  "picture": "https://example.com/avatar.jpg"
}
```

---

## User Management APIs

### 1. Get Users

```http
GET /api/get-users
Authorization: Bearer {access_token}
```

**Query Parameters:**
- `owner` (optional): Organization owner
- `field` (optional): Field to search
- `value` (optional): Search value
- `sortField` (optional): Sort field
- `sortOrder` (optional): "asc" or "desc"
- `p` (optional): Page number
- `pageSize` (optional): Page size

**Response:**
```json
{
  "data": [
    {
      "owner": "built-in",
      "name": "user123",
      "createdTime": "2023-01-01T00:00:00Z",
      "updatedTime": "2023-01-01T00:00:00Z",
      "id": "user123",
      "type": "normal-user",
      "displayName": "John Doe",
      "email": "john@example.com",
      "phone": "+1234567890",
      "avatar": "https://example.com/avatar.jpg",
      "isAdmin": false,
      "isGlobalAdmin": false,
      "isForbidden": false,
      "roles": ["role1", "role2"],
      "permissions": ["permission1", "permission2"]
    }
  ],
  "data2": null,
  "msg": "",
  "ok": true
}
```

### 2. Get User by ID

```http
GET /api/get-user?id={user_id}
Authorization: Bearer {access_token}
```

### 3. Get User by Name

```http
GET /api/get-user?name={user_name}&owner={owner}
Authorization: Bearer {access_token}
```

### 4. Create User

```http
POST /api/add-user
Authorization: Bearer {access_token}
Content-Type: application/json
```

**Request Body:**
```json
{
  "owner": "built-in",
  "name": "newuser",
  "createdTime": "2023-01-01T00:00:00Z",
  "updatedTime": "2023-01-01T00:00:00Z",
  "id": "newuser",
  "type": "normal-user",
  "password": "password123",
  "displayName": "New User",
  "firstName": "New",
  "lastName": "User",
  "email": "newuser@example.com",
  "phone": "+1234567890",
  "address": ["123 Main St", "City", "State", "12345"],
  "affiliation": "Organization",
  "tag": "tag1",
  "score": 0,
  "isAdmin": false,
  "isGlobalAdmin": false,
  "isForbidden": false,
  "signupApplication": "app-built-in",
  "properties": {
    "key1": "value1"
  },
  "roles": ["role1"],
  "permissions": ["permission1"]
}
```

### 5. Update User

```http
POST /api/update-user?id={user_id}
Authorization: Bearer {access_token}
Content-Type: application/json
```

**Request Body:** (Same structure as create, but with updated fields)

### 6. Delete User

```http
POST /api/delete-user?id={user_id}
Authorization: Bearer {access_token}
```

### 7. Check User Password

```http
POST /api/check-user-password
Authorization: Bearer {access_token}
Content-Type: application/json
```

**Request Body:**
```json
{
  "user": "user123",
  "password": "password123"
}
```

**Response:**
```json
{
  "data": true,
  "data2": null,
  "msg": "",
  "ok": true
}
```

---

## Application Management APIs

### 1. Get Applications

```http
GET /api/get-applications
Authorization: Bearer {access_token}
```

**Query Parameters:**
- `owner` (optional): Organization owner
- `field` (optional): Field to search
- `value` (optional): Search value
- `sortField` (optional): Sort field
- `sortOrder` (optional): "asc" or "desc"
- `p` (optional): Page number
- `pageSize` (optional): Page size

### 2. Get Application by ID

```http
GET /api/get-application?id={app_id}
Authorization: Bearer {access_token}
```

### 3. Create Application

```http
POST /api/add-application
Authorization: Bearer {access_token}
Content-Type: application/json
```

**Request Body:**
```json
{
  "owner": "built-in",
  "name": "my-app",
  "createdTime": "2023-01-01T00:00:00Z",
  "updatedTime": "2023-01-01T00:00:00Z",
  "displayName": "My Application",
  "logo": "https://example.com/logo.png",
  "homepageUrl": "https://my-app.com",
  "description": "My application description",
  "organization": "built-in",
  "cert": "certificate_content",
  "enablePassword": true,
  "enableSignUp": true,
  "enableSigninSession": true,
  "enableAutoSignin": false,
  "enableCodeSignin": false,
  "enableSamlCompress": false,
  "enableWebAuthn": false,
  "enableLinkWithEmail": false,
  "orgChoiceMode": "Username",
  "samlReplyUrl": "https://my-app.com/saml/callback",
  "providers": [],
  "signupItems": [],
  "grantTypes": ["authorization_code"],
  "organizationObj": null,
  "tags": ["tag1", "tag2"],
  "clientId": "client_id_here",
  "clientSecret": "client_secret_here",
  "redirectUris": ["https://my-app.com/callback"],
  "tokenFormat": "JWT",
  "expireInHours": 24,
  "refreshExpireInHours": 168,
  "signupUrl": "https://my-app.com/signup",
  "signinUrl": "https://my-app.com/signin",
  "forgetUrl": "https://my-app.com/forget",
  "affiliationUrl": "https://my-app.com/affiliation",
  "termsOfUse": "https://my-app.com/terms",
  "signupHtml": "<html>...</html>",
  "signinHtml": "<html>...</html>",
  "forgetHtml": "<html>...</html>",
  "affiliationHtml": "<html>...</html>",
  "wrapHtml": "<html>...</html>",
  "footerHtml": "<html>...</html>",
  "favicon": "https://example.com/favicon.ico",
  "passwordType": "plain",
  "passwordOptions": ["AtLeast6", "NoRepeat"],
  "isPublic": false,
  "properties": {
    "key1": "value1"
  }
}
```

### 4. Update Application

```http
POST /api/update-application?id={app_id}
Authorization: Bearer {access_token}
Content-Type: application/json
```

### 5. Delete Application

```http
POST /api/delete-application?id={app_id}
Authorization: Bearer {access_token}
```

---

## Organization Management APIs

### 1. Get Organizations

```http
GET /api/get-organizations
Authorization: Bearer {access_token}
```

### 2. Get Organization by ID

```http
GET /api/get-organization?id={org_id}
Authorization: Bearer {access_token}
```

### 3. Create Organization

```http
POST /api/add-organization
Authorization: Bearer {access_token}
Content-Type: application/json
```

**Request Body:**
```json
{
  "owner": "built-in",
  "name": "my-org",
  "createdTime": "2023-01-01T00:00:00Z",
  "updatedTime": "2023-01-01T00:00:00Z",
  "displayName": "My Organization",
  "websiteUrl": "https://my-org.com",
  "favicon": "https://example.com/favicon.ico",
  "passwordType": "plain",
  "passwordOptions": ["AtLeast6", "NoRepeat"],
  "countryCodes": ["US", "CA"],
  "tags": ["tag1", "tag2"],
  "domains": ["my-org.com"],
  "isGlobal": false,
  "properties": {
    "key1": "value1"
  }
}
```

### 4. Update Organization

```http
POST /api/update-organization?id={org_id}
Authorization: Bearer {access_token}
Content-Type: application/json
```

### 5. Delete Organization

```http
POST /api/delete-organization?id={org_id}
Authorization: Bearer {access_token}
```

---

## Role & Permission APIs

### 1. Get Roles

```http
GET /api/get-roles
Authorization: Bearer {access_token}
```

### 2. Get Role by ID

```http
GET /api/get-role?id={role_id}
Authorization: Bearer {access_token}
```

### 3. Create Role

```http
POST /api/add-role
Authorization: Bearer {access_token}
Content-Type: application/json
```

**Request Body:**
```json
{
  "owner": "built-in",
  "name": "admin",
  "createdTime": "2023-01-01T00:00:00Z",
  "updatedTime": "2023-01-01T00:00:00Z",
  "displayName": "Administrator",
  "description": "Administrator role with full access",
  "users": ["user1", "user2"],
  "roles": ["sub-role1"],
  "isEnabled": true,
  "properties": {
    "key1": "value1"
  }
}
```

### 4. Update Role

```http
POST /api/update-role?id={role_id}
Authorization: Bearer {access_token}
Content-Type: application/json
```

### 5. Delete Role

```http
POST /api/delete-role?id={role_id}
Authorization: Bearer {access_token}
```

### 6. Get Permissions

```http
GET /api/get-permissions
Authorization: Bearer {access_token}
```

### 7. Get Permission by ID

```http
GET /api/get-permission?id={permission_id}
Authorization: Bearer {access_token}
```

### 8. Create Permission

```http
POST /api/add-permission
Authorization: Bearer {access_token}
Content-Type: application/json
```

**Request Body:**
```json
{
  "owner": "built-in",
  "name": "read-users",
  "createdTime": "2023-01-01T00:00:00Z",
  "updatedTime": "2023-01-01T00:00:00Z",
  "displayName": "Read Users",
  "description": "Permission to read user data",
  "users": ["user1", "user2"],
  "roles": ["admin"],
  "resourceType": "User",
  "resources": ["user/*"],
  "actions": ["read"],
  "effect": "Allow",
  "isEnabled": true,
  "properties": {
    "key1": "value1"
  }
}
```

### 9. Update Permission

```http
POST /api/update-permission?id={permission_id}
Authorization: Bearer {access_token}
Content-Type: application/json
```

### 10. Delete Permission

```http
POST /api/delete-permission?id={permission_id}
Authorization: Bearer {access_token}
```

---

## Provider Management APIs

### 1. Get Providers

```http
GET /api/get-providers
Authorization: Bearer {access_token}
```

### 2. Get Provider by ID

```http
GET /api/get-provider?id={provider_id}
Authorization: Bearer {access_token}
```

### 3. Create Provider

```http
POST /api/add-provider
Authorization: Bearer {access_token}
Content-Type: application/json
```

**Request Body (OAuth Provider):**
```json
{
  "owner": "built-in",
  "name": "google",
  "createdTime": "2023-01-01T00:00:00Z",
  "updatedTime": "2023-01-01T00:00:00Z",
  "displayName": "Google",
  "category": "OAuth",
  "type": "Google",
  "clientId": "google_client_id",
  "clientSecret": "google_client_secret",
  "clientId2": "",
  "clientSecret2": "",
  "authUrl": "https://accounts.google.com/o/oauth2/auth",
  "tokenUrl": "https://oauth2.googleapis.com/token",
  "userApiUrl": "https://www.googleapis.com/oauth2/v2/userinfo",
  "userInfoUrl": "https://www.googleapis.com/oauth2/v2/userinfo",
  "userMapping": {
    "id": "id",
    "username": "email",
    "displayName": "name",
    "email": "email",
    "avatar": "picture"
  },
  "scope": "openid profile email",
  "audience": "",
  "isEnabled": true,
  "properties": {
    "key1": "value1"
  }
}
```

### 4. Update Provider

```http
POST /api/update-provider?id={provider_id}
Authorization: Bearer {access_token}
Content-Type: application/json
```

### 5. Delete Provider

```http
POST /api/delete-provider?id={provider_id}
Authorization: Bearer {access_token}
```

---

## Session & Token Management

### 1. Get Sessions

```http
GET /api/get-sessions
Authorization: Bearer {access_token}
```

### 2. Get Session by ID

```http
GET /api/get-session?id={session_id}
Authorization: Bearer {access_token}
```

### 3. Create Session

```http
POST /api/add-session
Authorization: Bearer {access_token}
Content-Type: application/json
```

**Request Body:**
```json
{
  "owner": "built-in",
  "name": "session123",
  "createdTime": "2023-01-01T00:00:00Z",
  "updatedTime": "2023-01-01T00:00:00Z",
  "application": "app-built-in",
  "username": "user123",
  "loginIp": "192.168.1.1",
  "clientIp": "192.168.1.1",
  "userAgent": "Mozilla/5.0...",
  "sessionId": "session_id_here",
  "expiredTime": "2023-01-02T00:00:00Z",
  "isActive": true,
  "properties": {
    "key1": "value1"
  }
}
```

### 4. Update Session

```http
POST /api/update-session?id={session_id}
Authorization: Bearer {access_token}
Content-Type: application/json
```

### 5. Delete Session

```http
POST /api/delete-session?id={session_id}
Authorization: Bearer {access_token}
```

### 6. Logout

```http
POST /api/logout
Authorization: Bearer {access_token}
```

---

## Audit & Logging APIs

### 1. Get Logs

```http
GET /api/get-logs
Authorization: Bearer {access_token}
```

**Query Parameters:**
- `owner` (optional): Organization owner
- `field` (optional): Field to search
- `value` (optional): Search value
- `sortField` (optional): Sort field
- `sortOrder` (optional): "asc" or "desc"
- `p` (optional): Page number
- `pageSize` (optional): Page size

### 2. Get Log by ID

```http
GET /api/get-log?id={log_id}
Authorization: Bearer {access_token}
```

### 3. Create Log

```http
POST /api/add-log
Authorization: Bearer {access_token}
Content-Type: application/json
```

**Request Body:**
```json
{
  "owner": "built-in",
  "name": "log123",
  "createdTime": "2023-01-01T00:00:00Z",
  "updatedTime": "2023-01-01T00:00:00Z",
  "organization": "built-in",
  "username": "user123",
  "requestUri": "/api/get-user",
  "action": "get-user",
  "object": "user123",
  "result": "success",
  "ip": "192.168.1.1",
  "userAgent": "Mozilla/5.0...",
  "method": "GET",
  "statusCode": 200,
  "response": "user data",
  "properties": {
    "key1": "value1"
  }
}
```

### 4. Update Log

```http
POST /api/update-log?id={log_id}
Authorization: Bearer {access_token}
Content-Type: application/json
```

### 5. Delete Log

```http
POST /api/delete-log?id={log_id}
Authorization: Bearer {access_token}
```
