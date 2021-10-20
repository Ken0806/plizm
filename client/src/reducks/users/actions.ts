import {
    DisableLockDescriptionAction, SignInAction, SignOutAction, SignUpAction
} from '../../util/types/redux/users';

export const SIGN_UP = 'SIGN_UP'
export const signUpAction: SignUpAction = (userState) => ({
  type: 'SIGN_UP',
  payload: {
    isSignedIn: true,
    uid: userState.uid,
    accessToken: userState.accessToken,
    client: userState.client,
    userId: userState.userId,
    userName: userState.userName,
    icon: userState.icon,
    needDescriptionAboutLock: userState.needDescriptionAboutLock,
  },
})

export const SIGN_IN = 'SIGN_IN'
export const signInAction: SignInAction = (userState) => ({
  type: 'SIGN_IN',
  payload: {
    isSignedIn: true,
    uid: userState.uid,
    accessToken: userState.accessToken,
    client: userState.client,
    userId: userState.userId,
    userName: userState.userName,
    icon: userState.icon,
    needDescriptionAboutLock: userState.needDescriptionAboutLock,
  },
})

export const SIGN_OUT = 'SIGN_OUT'
export const signOutAction: SignOutAction = () => ({
  type: 'SIGN_OUT',
  payload: {
    isSignedIn: false,
    uid: null,
    accessToken: null,
    client: null,
    userId: null,
    userName: null,
    icon: null,
    needDescriptionAboutLock: null,
    hasRightToUsePlizm: false,
  },
})

export const DISABLE_LOCK_DESCRIPTION = 'DISABLE_LOCK_DESCRIPTION'
export const disableLockDescriptionAction: DisableLockDescriptionAction = (userState) => ({
  type: 'DISABLE_LOCK_DESCRIPTION',
  payload: {
    needDescriptionAboutLock: userState.needDescriptionAboutLock,
  },
})
