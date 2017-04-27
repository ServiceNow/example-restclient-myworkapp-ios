# Example REST Client My Work App: iOS
This project contains source code for a native [iOS](https://developer.apple.com/ios/) application that interacts with ServiceNow's [REST APIs](https://docs.servicenow.com/bundle/helsinki-servicenow-platform/page/integrate/inbound_rest/concept/c_RESTAPI.html) including a [Scripted REST API](https://docs.servicenow.com/bundle/helsinki-servicenow-platform/page/integrate/custom_web_services/concept/c_CustomWebServices.html). The simple use case is a "MyWork" application which displays a user's current tasks and allows comments to be added. This application demonstrates how to build the MyWork app using iOS.

## Flavors of MyWork Application
* [Example REST Client My Work App: Android](https://github.com/ServiceNow/example-restclient-myworkapp-android-beta) : The "MyWork" application implemented using Android.
* [Example REST Client My Work App: Node.js](https://github.com/ServiceNow/example-restclient-myworkapp-nodejs) : The "MyWork" application implemented in Node JS.
* [Example REST Client My Work App: iOS](this repository): The "MyWork" application implemented in iOS.

## Architecture
Here is an overview of the MyWork application architecture. Note both this iOS application and the Node.js application are represented in the diagram.
![Architecture diagram](/images/arch_diagram.jpg "Architecture diagram")

---------------------------------------------------------------------------

## Prerequisites
* OS X [Xcode 7.3.1](https://developer.apple.com/download/more/) installed
* A ServiceNow instance ([Geneva Patch 3](https://docs.servicenow.com/bundle/geneva-release-notes/page/c2/geneva-patch-3-2.html) or later).
	* **Don't have a ServiceNow instance?** Get one **FREE** by signing up at https://developer.servicenow.com
	* Not sure what version of ServiceNow your instance is running?  [Determine running version](http://wiki.servicenow.com/index.php?title=Upgrades_Best_Practices#Prepare_for_Upgrading)

--------------------------------------------------------------------------

## Setup the iOS project on your machine
1. Clone the project and install dependencies
	* Git clone
	```bash
	$ git clone https://github.com/ServiceNow/example-restclient-myworkapp-ios.git
	$ cd example-restclient-myworkapp-ios
	$ sudo gem install cocoapods
	$ pod install
	```
	--or--
	* [Download](https://github.com/ServiceNow/example-restclient-myworkapp-ios/archive/master.zip) the full project as a Zip file
	```bash
	<unzip>
	$ cd example-restclient-myworkapp-ios
	$ sudo gem install cocoapods
	$ pod install
	```

   * **NOTE:** **pod install** requires permission to modify project directory. In case you run into issues doing the pod install modify permissions to the project directory by running
   	```bash
	sudo chown -R '[username]' ~/example-restclient-myworkapp-ios
	```
   Make sure the **MyTasks.xcworkspace** file was generated within xcode project directory.

2. Install the **MyWork Update Set** in your ServiceNow instance. This is a ServiceNow scoped application which contains the **Task Tracker API** Scripted REST API and related files. Note that you must have the admin role on your ServiceNow instance to install update sets.
	1. Obtain the "My Work" update set
		* Download the update set from [share.servicenow.com](https://share.servicenow.com/app.do#/detailV2/e43cf2f313de5600e77a36666144b0b4/overview)
<br/>--or--
		* Get the update set from the directory where you cloned the GitHub repository: **example-restclient-myworkapp-ios/mywork_update_set/sys_remote_update_set_2f48a7d74f4652002fa02f1e0210c785.xml**
	2. Install the Update Set XML
		1. In your ServiceNow instance, navigate to **Retrieved Update Sets**
		2. Click **Import Update Set from XML**
		3. Click **Choose File**, browse to find the downloaded update set XML file from Step 1, and click **Upload**
		4. Click to open the **My Work** update set
		5. Click **Preview Update Set**
		6. Click **Commit Update Set**
	3. Verify the MyWork Update Set installed using the API Explorer
		1. In your ServiceNow instance, navigate to **Scripted REST APIs**
		2. Open the **Task Tracker** Scripted REST API, then open the **My Tasks** API resource
		3. Click **Explore REST API** (this opens the API in the REST API Explorer)
		4. In the API Explorer, click **Send** and verify the API request is sent and receives a **200-OK** response

--------------------------------------------------------------------------

## Loading & running the iOS application in **XCode**
* Open **`MyTasks.xcworkspace`** with **XCode**.
 ![My_Tasks_workspace file](/images/pod_install_result.png)
* To run the project, click the "play" button to build and run the application.

![Build and run](/images/build_and_run.png)

--------------------------------------------------------------------------

## About the application
This is a native iOS application which makes HTTP calls to the **Task Tracker** Scripted REST API to get the list of tasks assigned to the logged-in user and to allow the user to add comments.

### Functional flow

#### 1. Login
The app tries to login using previous authentication information stored in the iOS Keychain. If not available, the app displays the login screen.

![Login](/images/login.png)

The login screen prompts you to input your ServiceNow instance name. For example, if your instance URL is https://myinstance.service-now.com, then enter `myinstance` into the Instance text box.

Enter the user ID and password for a user on the instance. This application uses Basic Authentication to manage user authentication with the ServiceNow REST API. When a user enters credentials, an HTTP GET call is made to retrieve the user account from the `sys_user` table using the REST Table API. This call establishes a session with the ServiceNow instance.

On successful login the app stores authentication info (instance, username, and password) into the iOS keychain and then transitions to the task list view. On login failure, the user is directed to the login screen to reenter credentials.

After login, the application displays the tasks assigned to the user grouped by task type. The application uses the **Task Tracker API** to retrieve the list of tasks from ServiceNow. The logged in user must have access to view the tasks (such as Incidents, Problems, Tickets) for those tasks to be returned in the REST API and subsequently displayed in the 'MyWork App'.

**> REST API Call:** Get user details (Table API)
```
GET /api/now/v2/table/sys_user?user_name=john.doe
```

#### 2. View my tasks
![Task List](/images/task_list.png)

Click an item in the list to open the task details.

**> REST API Call:** Get my tasks (Task Tracker API)
```
GET /api/x_snc_my_work/v1/tracker/task
```

#### 3. View task detail/add comment
![Task Details](/images/task_detail.png)

Comments can be added to a task and will appear on the work notes for the task both in this application as well as within ServiceNow.

**> REST API Calls:** Get comments, Add comment (Task Tracker API, Table API)
```
GET /api/now/v2/table/sys_journal_field?element_id=<task_id>

POST /api/x_snc_my_work/v1/tracker/task/{task_id}/comment
{"comment":"Hello, world!"}
```

### Application Flow Detail
![App Flow](/images/node_flow.png)

#### Modules
* Reusable event based Authentication Module.
* Callback API module to communicate with ServiceNow REST APIs.
* View to show tasks assigned to the logged-in user and to pose comments to tasks.

##### Authentication module
The `Authenticator` and `AuthSession` object singletons are provided to encapsulate the authentication mechanism.
* `AuthSession` holds authenticated user info such as name and can be used to see if session is authenticated.
* `Authenticator`
	* Exposes two messages (functions) to authenticate using username, password or keychain values: `authenticate` and `authenticateFromKeychain`
	* By default is configured to do BasicAuth but can be modified to use OAuth 2.0 password flow. Note you would need to configure the OAuth provider on the instance including setting up a client ID and client secret.
	* Dispatches two events, `login_event` or `ks_login_event` on completion of authentication. Callers can listen to these events and act on them.

##### RESTAPIRequestHandler
Encapsulates all REST API calls required by views to retrieve task list, retrieve task details and save task comments.
This uses `AFHTTPSessionManagerFactory` to get an `AFHTTPSessionManager`, which is used to make HTTP calls. `AFHttpSessionManager` manages the session by using session cookies stored after the initial successful REST API request.

##### Story board, Views and View controllers
*	Views
	*	LoginProgress
	*	LoginView
	*	TaskListView
	*	DetailView
*	View Controllers
	*	LoginProgressView
	*	LoginView
	*	TaskListView
	*	DetailView
*	View controllers control the flow of views. 
*	The LoginProgressView and LoginView controllers use the Authenticator module while the TaskListView and DetailView controllers use the API Module (RESTAPIRequestHandler).

##### Quirks
For testing purposes, the App Transport settings have been configured to accept all HTTPS interaction without adding certificates from ServiceNow. In a production application, we wouldn't do this.

--------------------------------------------------------------------------

## Sample REST API requests/responses

### 1. Login/retrieve user account
The initial request to ServiceNow submits the user credentials and retrieves the user account. This establishes a session with ServiceNow which can be maintained by saving and resending the cookies returned from the first request.

Here is an equivalent sample curl request. It saves the response cookies in a new file called cookies.txt. The same file is specified on subsequent request in order to apply all cookies.
```
$ curl --verbose --request GET \
--header "Accept: application/json" \
--user "john.doe:password" --cookie cookies.txt --cookie-jar cookies.txt \
 "https://myinstance.service-now.com/api/now/v2/table/sys_user?user_name=john.doe&sysparm_fields=user_name,first_name,last_name,sys_id"

> GET /api/now/v2/table/sys_user?user_name=john.doe&sysparm_fields=user_name,first_name,last_name,sys_id HTTP/1.1
> Authorization: Basic am9obi5kb2U6cGFzc3dvcmQ=
> Host: myinstance.service-now.com
> Accept: application/json

< HTTP/1.1 200 OK
< Set-Cookie: JSESSIONID=3BFF4F3A8AC5F4695E0477F6F8E34BDE;Secure; Path=/; HttpOnly
< Set-Cookie: glide_user="";secure; Expires=Thu, 01-Jan-1970 00:00:10 GMT; Path=/; HttpOnly
< Set-Cookie: glide_user_session="";secure; Expires=Thu, 01-Jan-1970 00:00:10 GMT; Path=/; HttpOnly
< Set-Cookie: glide_user_route=glide.787db27f9eb4d8275f143168c5481c86;secure; Expires=Mon, 27-Mar-2084 19:32:44 GMT; Path=/; HttpOnly
< Set-Cookie: glide_session_store=292391354F4212008A5AB895F110C722; Expires=Wed, 09-Mar-2016 16:48:37 GMT; Path=/; HttpOnly
< Set-Cookie: BIGipServerpool_myinstance=2927640842.52542.0000; path=/
< X-Total-Count: 1
< Pragma: no-store,no-cache
< Cache-control: no-cache,no-store,must-revalidate,max-age=-1
< Expires: 0
< Content-Type: application/json;charset=UTF-8
< Transfer-Encoding: chunked
{
  "result": [
    {
      "first_name": "John",
      "last_name": "Doe",
      "sys_id": "ea2bc1b14f4212008a5ab895f110c7d1",
      "user_name": "john.doe"
    }
  ]
}
```

### 2. Get user's tasks
Next, the user's tasks are retrieved. Note how the cookies from the first request are sent with subsequent requests, and user credentials no longer need to be sent:
```
$ curl --verbose --request GET \
--header "Accept: application/json" \
--cookie cookies.txt --cookie-jar cookies.txt \
 "https://myinstance.service-now.com/api/x_snc_my_work/v1/tracker/task"

> GET /api/x_snc_my_work/v1/tracker/task HTTP/1.1
> Host: myinstance.service-now.com
> Cookie: BIGipServerpool_myinstance=2927640842.52542.0000; JSESSIONID=3BFF4F3A8AC5F4695E0477F6F8E34BDE; glide_session_store=292391354F4212008A5AB895F110C722; glide_user_route=glide.787db27f9eb4d8275f143168c5481c86
> Accept: application/json

< HTTP/1.1 200 OK
< Set-Cookie: glide_user="U0N2Mjo1ODczMTEzNTIxNDIxMjAwOWE3NDgyZDFlZjg3Mzk4OQ==";Secure; Version=1; Max-Age=2147483647; Expires=Mon, 27-Mar-2084 19:34:00 GMT; Path=/; HttpOnly
< Set-Cookie: glide_user_session="U0N2Mjo1ODczMTEzNTIxNDIxMjAwOWE3NDgyZDFlZjg3Mzk4OQ==";Secure; Version=1; Path=/; HttpOnly
< Set-Cookie: glide_session_store=292391354F4212008A5AB895F110C722; Expires=Wed, 09-Mar-2016 16:24:53 GMT; Path=/; HttpOnly
< Pragma: no-store,no-cache
< Cache-control: no-cache,no-store,must-revalidate,max-age=-1
< Expires: 0
< Content-Type: application/json;charset=UTF-8
< Transfer-Encoding: chunked
{
  "result": {
    "Incident": [
      {
        "short_desc": "my computer doesn't work",
        "snowui": "https://myinstance.service-now.com/incident.do?sys_id=061c92d26f030200d7aecd9c5d3ee4f8",
        "number": "INC0010021",
        "sys_id": "061c92d26f030200d7aecd9c5d3ee4f8",
        "link": "https://myinstance.service-now.com/api/now/v2/table/incident/061c92d26f030200d7aecd9c5d3ee4f8",
        "created": "2015-10-14 07:45:55"
      }
    ],
    "Problem": [
      {
        "short_desc": "Unknown source of outage",
        "snowui": "https://myinstance.service-now.com/problem.do?sys_id=d7296d02c0a801670085e737da016e70",
        "number": "PRB0000011",
        "sys_id": "d7296d02c0a801670085e737da016e70",
        "link": "https://myinstance.service-now.com/api/now/v2/table/problem/d7296d02c0a801670085e737da016e70",
        "created": "2014-02-04 04:58:15"
      },
      {
        "short_desc": "Getting NPE stack trace accessing link",
        "snowui": "https://myinstance.service-now.com/problem.do?sys_id=fb9620914fc212008a5ab895f110c7c4",
        "number": "PRB0040010",
        "sys_id": "fb9620914fc212008a5ab895f110c7c4",
        "link": "https://myinstance.service-now.com/api/now/v2/table/problem/fb9620914fc212008a5ab895f110c7c4",
        "created": "2016-03-07 23:47:43"
      }
    ]
  }
}
```

### 3. Add a comment
To add a comment, send a POST request with a JSON payload using the Task Tracker API.

```
$ curl --verbose --request POST \
--header "Accept: application/json" --header "Content-Type: application/json" \
--cookie cookies.txt --cookie-jar cookies.txt \
--data '{"comment":"Hello, world!"}' \
 "https://myinstance.service-now.com/api/x_snc_my_work/v1/tracker/task/d7296d02c0a801670085e737da016e70/comment"

> POST /api/x_snc_my_work/v1/tracker/task/d7296d02c0a801670085e737da016e70/comment HTTP/1.1
> Host: myinstance.service-now.com
> Cookie: BIGipServerpool_myinstance=2927640842.52542.0000; JSESSIONID=3BFF4F3A8AC5F4695E0477F6F8E34BDE; glide_session_store=292391354F4212008A5AB895F110C722; glide_user="U0N2Mjo1ODczMTEzNTIxNDIxMjAwOWE3NDgyZDFlZjg3Mzk4OQ=="; glide_user_route=glide.787db27f9eb4d8275f143168c5481c86; glide_user_session="U0N2Mjo1ODczMTEzNTIxNDIxMjAwOWE3NDgyZDFlZjg3Mzk4OQ=="
> Accept: application/json
> Content-Type: application/json
> Content-Length: 27
{"comment":"Hello, world!"}

< HTTP/1.1 201 Created
< Set-Cookie: glide_session_store=292391354F4212008A5AB895F110C722; Expires=Wed, 09-Mar-2016 16:29:58 GMT; Path=/; HttpOnly
< Content-Type: application/json
< Transfer-Encoding: chunked
{
  "data": "Successfully inserted"
}
```
