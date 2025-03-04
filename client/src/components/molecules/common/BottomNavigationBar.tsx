import { push } from 'connected-react-router';
import { VFC } from 'react';
import { useDispatch } from 'react-redux';

import HomeRoundedIcon from '@mui/icons-material/HomeRounded';
import NotificationsNoneRoundedIcon from '@mui/icons-material/NotificationsNoneRounded';
import SearchIcon from '@mui/icons-material/Search';
import { BottomNavigation, BottomNavigationAction, Theme } from '@mui/material';
import createStyles from '@mui/styles/createStyles';
import makeStyles from '@mui/styles/makeStyles';

import LogoIconActive from '../../../assets/img/LogoIconActive2.png';
import LogoIconInactive from '../../../assets/img/LogoIconInactive2.png';

const useStyles = makeStyles(() =>
  createStyles({
    buttomNav: {
      backgroundColor: '#333333',
    },
    logoIcon: {
      width: 26.25,
    },
  }),
)

const useStylesToOverrideColor = makeStyles((theme: Theme) =>
  createStyles({
    root: {
      color: theme.palette.primary.main,
      '&$selected': {
        color: theme.palette.info.main,
      },
    },
    selected: {},
  }),
)

type Props = {
  activeNav: 'home' | 'search' | 'notifications' | 'refract' | 'profile' | 'settings' | 'none'
}

const BottomNavigationBar: VFC<Props> = ({ activeNav }) => {
  const classes = useStyles()
  const classesToOverrideColor = useStylesToOverrideColor()
  const dispatch = useDispatch()

  return (
    <BottomNavigation
      showLabels
      value={`/${activeNav}`}
      onChange={(event, newValue) => {
        dispatch(push(newValue))
      }}
      className={classes.buttomNav}
    >
      <BottomNavigationAction classes={classesToOverrideColor} value="/home" icon={<HomeRoundedIcon />} />
      <BottomNavigationAction classes={classesToOverrideColor} value="/search" icon={<SearchIcon />} />
      <BottomNavigationAction
        classes={classesToOverrideColor}
        value="/notifications"
        icon={<NotificationsNoneRoundedIcon />}
      />
      {activeNav === 'refract' && (
        <BottomNavigationAction
          classes={classesToOverrideColor}
          value="/refracted_posts"
          icon={<img src={LogoIconActive} alt="ロゴアイコン" className={classes.logoIcon} />}
        />
      )}
      {activeNav !== 'refract' && (
        <BottomNavigationAction
          classes={classesToOverrideColor}
          value="/refracted_posts"
          icon={<img src={LogoIconInactive} alt="ロゴアイコン" className={classes.logoIcon} />}
        />
      )}
    </BottomNavigation>
  )
}

export default BottomNavigationBar
