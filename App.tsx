import React from 'react';
import { NavigationContainer } from '@react-navigation/native';
import { createNativeStackNavigator } from '@react-navigation/native-stack';
import SignInScreen from './app/signin';
import SignUpScreen from './app/signup';
import { navigationTheme } from './theme';
import { 
  TerminalScreen, 
  TerminalText, 
  TerminalHeader,
  ASCIILoader,
  BootSequence 
} from './components/Terminal';

// Terminal-styled Home screen
function HomeScreen() {
  const [booting, setBooting] = React.useState(true);
  
  const bootMessages = [
    'Initializing MINDCHAIN protocol...',
    'Loading Solana Web3 connections...',
    'Establishing WebSocket channels...',
    'Mounting document storage systems...',
    'Activating AI chat interfaces...',
    'Study platform ready.',
  ];

  return (
    <TerminalScreen title="MINDCHAIN // STUDY PLATFORM" showHeader={!booting}>
      {booting ? (
        <BootSequence 
          messages={bootMessages}
          onComplete={() => setBooting(false)}
          speed={800}
        />
      ) : (
        <>
          <TerminalHeader level={2}>SYSTEM STATUS: ONLINE</TerminalHeader>
          <TerminalText color="accent">Welcome to the terminal interface.</TerminalText>
          <TerminalText color="secondary">Available modules:</TerminalText>
          <TerminalText>• Study Rooms (Token-Gated)</TerminalText>
          <TerminalText>• Document Chat (AI-Powered)</TerminalText>
          <TerminalText>• NFT Minting & Achievements</TerminalText>
          <TerminalText>• Wallet Integration</TerminalText>
        </>
      )}
    </TerminalScreen>
  );
}

const Stack = createNativeStackNavigator();

export default function App() {
  return (
    <NavigationContainer theme={navigationTheme}>
      <Stack.Navigator initialRouteName="SignIn" screenOptions={{ headerShown: false }}>
        <Stack.Screen name="SignIn" component={SignInScreen} />
        <Stack.Screen name="SignUp" component={SignUpScreen} />
        <Stack.Screen name="Home" component={HomeScreen} />
      </Stack.Navigator>
    </NavigationContainer>
  );
}
