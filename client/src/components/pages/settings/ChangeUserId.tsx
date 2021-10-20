import { ContainedRoundedCornerButton, ErrorMessage } from 'components/atoms';
import { HeaderWithBackAndTitle } from 'components/molecules';
import { DefaultTemplate } from 'components/templates';
import { useState, VFC } from 'react';
import { useDispatch, useSelector } from 'react-redux';
import { editUserId } from 'reducks/users/operations';
import { getUserId } from 'reducks/users/selectors';
import { Users } from 'util/types/redux/users';

import { Box, TextField } from '@mui/material';

const ChangeUserId: VFC = () => {
  const dispatch = useDispatch()

  const selector = useSelector((state: { users: Users }) => state)
  const currentUserId = getUserId(selector)

  const [disabled, setDisabled] = useState(false)
  const [userId, setUserId] = useState(currentUserId)
  const [error, setError] = useState('')

  const handleChangeUserId = (e: React.ChangeEvent<HTMLTextAreaElement>) => {
    const text = e.target.value
    const textLength = text.length
    if (textLength < 4) {
      setDisabled(true)
      setUserId(text)
    } else if (textLength >= 4 && textLength <= 15) {
      setDisabled(false)
      setUserId(text)
    }
  }

  const handleClickToChangeUserId = () => {
    dispatch(editUserId(userId, setError))
  }

  const returnHeaderFunc = () => (
    <Box sx={{ display: 'flex', alignItems: 'center', width: '100%' }}>
      <HeaderWithBackAndTitle title="ユーザーID変更" />
      <Box sx={{ marginLeft: 'auto', marginRight: 1, width: 104 }}>
        <ContainedRoundedCornerButton
          onClick={handleClickToChangeUserId}
          label="変更"
          backgroundColor="#2699fb"
          disabled={disabled}
        />
      </Box>
    </Box>
  )

  return (
    <DefaultTemplate activeNavTitle="settings" returnHeaderFunc={returnHeaderFunc}>
      <Box p={3}>
        <TextField
          label="ユーザーID (4文字以上15文字以内)"
          value={userId}
          color="secondary"
          focused
          required
          fullWidth
          onChange={handleChangeUserId}
          sx={{ marginBottom: 1 }}
        />
        <ErrorMessage error={error} />
      </Box>
    </DefaultTemplate>
  )
}

export default ChangeUserId
