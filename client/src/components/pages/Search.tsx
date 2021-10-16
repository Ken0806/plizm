import { AccountDrawer } from 'components/organisms';
import { DefaultTemplate } from 'components/templates';
import { push } from 'connected-react-router';
import { useEffect, useState, VFC } from 'react';
import { useDispatch, useSelector } from 'react-redux';
import { getUser } from 'reducks/users/selectors';
import { axiosBase } from 'util/api';
import { RequestHeaders, User } from 'util/types/hooks/users';

import SearchIcon from '@mui/icons-material/Search';
import { TabContext, TabList, TabPanel } from '@mui/lab';
import {
    Avatar, Box, Divider, Hidden, InputAdornment, LinearProgress, Tab, TextField, Theme
} from '@mui/material';
import createStyles from '@mui/styles/createStyles';
import makeStyles from '@mui/styles/makeStyles';

import { Users } from '../../util/types/redux/users';

const useStyles = makeStyles((theme: Theme) =>
  createStyles({
    input: {
      color: theme.palette.primary.light,
    },
    userName: {
      fontSize: 15,
      fontWeight: 'bold',
    },
    userId: {
      fontSize: 13,
    },
  }),
)

const useTabStyles = makeStyles((theme: Theme) =>
  createStyles({
    root: {
      color: theme.palette.text.disabled,
      fontSize: 15,
      '&:hover': {
        opacity: '0.7',
        transition: 'all 0.3s ease 0s',
      },
      '&.Mui-selected': {
        color: theme.palette.info.main,
        fontWeight: 'bold',
      },
    },
    indicator: {
      backgroundColor: 'red',
      color: 'red',
    },
  }),
)

const useTabListStyles = makeStyles((theme: Theme) =>
  createStyles({
    indicator: {
      backgroundColor: theme.palette.info.main,
    },
  }),
)

type Reponse = {
  users: Array<User>
}

const Search: VFC = () => {
  const classes = useStyles()
  const tabClasses = useTabStyles()
  const tabListClasses = useTabListStyles()

  const dispatch = useDispatch()
  const selector = useSelector((state: { users: Users }) => state)

  const [query, setQuery] = useState('')
  const [searchedUsers, setSearchedUsers] = useState<Array<User>>([])
  const [loading, setLoading] = useState(false)
  const [tabValue, setTabValue] = useState<'アカウント'>('アカウント')

  const handleChangeOfInput = (event: React.ChangeEvent<HTMLInputElement>) => {
    setQuery(event.target.value)
  }

  const handleChangeTab = (event: React.SyntheticEvent, newValue: 'アカウント') => {
    setTabValue(newValue)
  }

  useEffect(() => {
    setLoading(true)
    if (!query) {
      setSearchedUsers([])
      setLoading(false)

      return
    }
    const user = getUser(selector)
    const requestHeaders: RequestHeaders = {
      'access-token': user.accessToken,
      client: user.client,
      uid: user.uid,
    }
    axiosBase
      .get<Reponse>(`/v1/search/users?q=${query}`, { headers: requestHeaders })
      .then((response) => {
        setSearchedUsers(response.data.users)
      })
      .catch((errors) => {
        console.log(errors)
      })
      .finally(() => {
        setLoading(false)
      })
  }, [query, selector])

  const returnHeaderFunc = () => (
    <>
      <Hidden smUp>
        <AccountDrawer />
      </Hidden>
      <TextField
        id="input-with-icon-textfield"
        InputProps={{
          startAdornment: (
            <InputAdornment position="start">
              <SearchIcon sx={{ color: '#86868B' }} />
            </InputAdornment>
          ),
          className: classes.input,
        }}
        variant="outlined"
        fullWidth
        sx={{
          width: '100%',
          margin: '0 16px',
          backgroundColor: 'rgba(123,123,123,0.4)',
          borderRadius: 1,
        }}
        size="small"
        color="info"
        onChange={handleChangeOfInput}
      />
    </>
  )

  return (
    <DefaultTemplate activeNavTitle="search" returnHeaderFunc={returnHeaderFunc}>
      <Box sx={{ width: '100%' }}>
        {loading && <LinearProgress color="info" />}
        <TabContext value={tabValue}>
          <TabList onChange={handleChangeTab} aria-label="Search tabs" classes={tabListClasses} centered>
            <Tab label="アカウント" value="アカウント" sx={{ width: '100%' }} classes={tabClasses} />
          </TabList>
          <TabPanel value="アカウント" sx={{ padding: 0 }}>
            {searchedUsers.length > 0 &&
              searchedUsers.map((searchedUser) => (
                <div key={searchedUser.user_id}>
                  <Box
                    sx={{ display: 'flex', padding: 1, width: '100%' }}
                    onClick={() => {
                      dispatch(push(`/${searchedUser.user_id}`))
                    }}
                    component="button"
                  >
                    <Avatar alt="Searched user" src={searchedUser.image_url} sx={{ marginRight: 1 }} />
                    <Box sx={{ display: 'flex', flexDirection: 'column' }}>
                      <span className={classes.userName}>{searchedUser.user_name}</span>
                      <span className={classes.userId}>@{searchedUser.user_id}</span>
                    </Box>
                  </Box>
                  <Divider sx={{ backgroundColor: '#EEEEEE' }} />
                </div>
              ))}
          </TabPanel>
        </TabContext>
      </Box>
    </DefaultTemplate>
  )
}
export default Search
