
// Copyright 2012-2013 SourceGear, LLC dba Zumero
// All Rights Reserved

#ifndef SQLITE_VERSION_NUMBER
#error sqlite3.h must be #included before zumero_register.h
#endif

#if SQLITE_VERSION_NUMBER < 3007011
#error Zumero requires SQLite 3.7.11 or higher
#endif

#ifdef __cplusplus
extern "C" 
{
#endif

int zumero_register(sqlite3 *db);

#ifdef __cplusplus
}
#endif

