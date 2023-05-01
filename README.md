# EzRider

EzRider is a mobile app developed using Flutter that allows users to collect different data modalities for a pothole location and road roughness deep learning task. The app aims to help users and transportation agencies identify road quality issues and improve road maintenance.

## Data Collection

The app collects the following information:

- Images: EzRider captures images of the roads the user is driving on.

- Accelerometer data: EzRider records 3-dimensional accelerometer data, which provides information on the roughness of the road.

- GPS location: The app records the user's latitude and longitude using the phone's GPS. 

Here is a JSON object showing a sample data point:

```
{"2023-03-21T18:24:46.833727":
  {
  "path":"/var/mobile/Containers/Data/Application/862AE1CB-F5D9-46FC-9AEA-DC36D4F4DF21/Documents/camera/pictures/CAP_C6A59ED2-B42D-48A3-B844-8C202C714CBD.jpg.jpg",
  "x":0.18534222394227984,
  "y":0.04553083181381226,
  "z":0.010495567321777345,
  "lat":42.54766260841556,
  "long":-71.37988141788043
  }
}
```

## Installation and Usage

To install EzRider, follow these steps:

1. Contact the owner of this repository to gain access of the app on TestFlight.
2. Install TestFlight on your iPhone from the App Store.
3. Open TestFlight and install the EZRider App.

Once EzRider is installed, you can use it to collect data on road conditions as you drive. The app will capture images, accelerometer data, and GPS location when prompted, which can be used to identify potholes and rough road conditions. The aggregated data will be shown on a map platform supported by the google map API where the detected potholes will be displayed in a orderly fashion.

## Future Developments

In the future, we plan to add several new features and improvements to the EzRider app. Some of these include:

- Improved machine learning algorithms to identify potholes and road roughness with higher accuracy.
- Enhanced data visualization and analysis tools to help researchers and transportation agencies better understand road conditions.
- Improved user interface and user experience to make the app more intuitive and user-friendly.

## Pothole Recognition Repository

We have also created a repository that contains a CNN model trained on open-source datasets for pothole recognition. You can find the repository [here](https://github.com/aymane-eljerari/pothole-localization).

## Data Privacy and Security

The data privacy and security of our users is of the utmost importance to us. EzRider anonymizes all user data to ensure that there is no connection between the data collected and the user.

## Screenshots

![Image3](screenshots/IMG-1614.PNG)

![Image3](screenshots/IMG-1615.PNG)
