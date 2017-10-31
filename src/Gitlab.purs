module Gitlab where

import Prelude

import Control.Monad.Aff (Aff)
import Data.Either (Either(..))
import Data.Maybe (Maybe(..))
import Network.HTTP.Affjax (AJAX, get)
import Simple.JSON (class ReadForeign, class WriteForeign, readJSON)

import Debug.Trace as Debug

type BaseUrl = String
type Token = String

type Project =
  { id   :: Int
  , name :: String
  }

type User =
  { avatar_url :: String
  }

type Commit =
  { title    :: String
  , short_id :: String
  }

type Pipeline =
  { id     :: Int
  , status :: String -- TODO: make enum?
  }

type Job =
  { project     :: Maybe Project
  , user        :: User
  , commit      :: Commit
  , ref         :: String
  , pipeline    :: Pipeline
  , created_at  :: String
  , started_at  :: Maybe String
  , finished_at :: Maybe String
  }

type Projects = Array Project
type Jobs = Array Job


getProjects :: forall a. BaseUrl -> Token -> Aff (ajax :: AJAX | a) Projects
getProjects baseUrl token = do
  let url = baseUrl
            <> "/api/v4/projects?private_token="
            <> token
            <> "&simple=true&per_page=20&order_by=last_activity_at"
  projectsRes <- get url
  let ps = case readJSON projectsRes.response of
        Left e -> []
        Right projects -> projects
  pure ps


getJobs :: forall a. BaseUrl -> Token -> Project -> Aff (ajax :: AJAX | a) Jobs
getJobs baseUrl token project = do
  let url = baseUrl
            <> "/api/v4/projects/"
            <> show project.id
            <> "/jobs?private_token="
            <> token
            <> "&per_page=100"
  jobsRes <- get url
  let js = case readJSON jobsRes.response of
        Left e -> do
          let _ = Debug.spy $ show e
          []
        Right jobs -> jobs
  pure js
