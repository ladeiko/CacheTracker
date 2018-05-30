# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/).

## 1.1.3
### Fixed
> 'weak' should not be applied to a property declaration in a protocol and will be disallowed in future versions"

on CacheTracker delegate property for swift >= 4.1.

## 1.1.2
### Changed
 * Add workaround for ```NSFetchedResultsController``` **fetchLimit** problem - now reload action is sent by coredata cachetracker if limit is exceeded

## 1.1.1
### Changed
 * Made **init** of CacheTransaction public.

## 1.1.0
### Added
 * **fetchLimit** to CacheRequest (NOTE: supported only by CoreDataCacheTracker!, for Real is ignored)