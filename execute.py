import json
import os

if __name__ == "__main__":

    db_secret = {}
    if 'DB_SECRET_ARN' in os.environ:
        import boto3
        secrets_client = boto3.client('secretsmanager')
        db_secret = json.loads(secrets_client.get_secret_value(
            SecretId=os.environ['DB_SECRET_ARN']
        )['SecretString'])

    user = os.getenv('DB_USER', db_secret.get('username', None))
    password = os.getenv('DB_PASSWORD', db_secret.get('password', None))
    host = os.getenv('DB_HOST', db_secret.get('host', None))
    port = os.getenv('DB_PORT', db_secret.get('port', None))
    db_name = os.getenv('DB_NAME', db_secret.get('dbname', None))

    if user is None:
        raise ValueError(
            'Neither the "db_user" variable nor a "user" field in a secret were provided')
    if password is None:
        raise ValueError(
            'Neither the "db_password" variable nor a "password" field in a secret were provided')
    if host is None:
        raise ValueError(
            'Neither the "db_host" variable nor a "host" field in a secret were provided')
    if port is None:
        raise ValueError(
            'Neither the "db_port" variable nor a "port" field in a secret were provided')

    # Port should be in an integer format
    port = int(port)

    statements = json.loads(os.environ['DB_STATEMENTS'])
    commit_independently = json.loads(os.environ['DB_COMMIT_INDEPENDENTLY'])
    dictionary_result = json.loads(os.environ['DB_DICTIONARY_RESULT'])

    results = []

    if os.environ['DB_TYPE'].lower() == 'mysql':
        import mysql.connector
        with mysql.connector.connect(autocommit=commit_independently, user=user, password=password, host=host, port=port, database=db_name) as cnx:
            with cnx.cursor(dictionary=dictionary_result) as cur:
                for statement in statements:
                    err = None
                    try:
                        cur.execute(statement['sql'], statement['data'])
                        if cur.description is None:
                            results.append({
                                'query': cur.statement,
                                'results': None,
                                'last_row_id': cur.lastrowid
                            })
                        else:
                            res = cur.fetchall()
                            results.append({
                                'query': cur.statement,
                                'results': res,
                                'last_row_id': cur.lastrowid
                            })
                    except Exception as e:
                        err = e
                    if err is not None:
                        permitted_exceptions = statement.get(
                            'permitted_exceptions', [])
                        if permitted_exceptions is None:
                            permitted_exceptions = []
                        if type(err).__name__ in permitted_exceptions:
                            results.append({
                                'query': cur.statement,
                                'results': None,
                                'last_row_id': None
                            })
                        else:
                            err_msg = str(err)
                            if hasattr(err, 'message'):
                                err_msg = err.message
                            if hasattr(cur, 'query') and cur.query is not None:
                                raise Exception(
                                    'Exception: {}\nStatement: {}\nError: {}'.format(type(err).__name__, cur.query, err_msg))
                            else:
                                raise Exception(
                                    'Exception: {}\nStatement: {}\nData: {}\nError: {}'.format(type(err).__name__, statement['sql'], statement['data'], err_msg))
            if not commit_independently:
                cnx.commit()

    elif os.environ['DB_TYPE'].lower() == 'postgresql':
        # If no database name was specified, use the most common default
        if db_name is None:
            db_name = 'postgres'

        import psycopg2
        from psycopg2.extensions import ISOLATION_LEVEL_AUTOCOMMIT
        cursor_factory = None
        if dictionary_result:
            import psycopg2.extras
            cursor_factory = psycopg2.extras.RealDictCursor
        cnx = psycopg2.connect(user=user, password=password,
                               host=host, port=port, dbname=db_name)
        if commit_independently:
            cnx.set_isolation_level(ISOLATION_LEVEL_AUTOCOMMIT)
        try:
            with cnx.cursor(cursor_factory=cursor_factory) as cur:
                for statement in statements:
                    err = None
                    try:
                        cur.execute(statement['sql'], statement['data'])
                        if cur.description is None:
                            results.append({
                                'query': cur.query.decode("utf-8"),
                                'results': None,
                                'last_row_id': cur.lastrowid
                            })
                        else:
                            res = cur.fetchall()
                            results.append({
                                'query': cur.query.decode("utf-8"),
                                'results': res,
                                'last_row_id': cur.lastrowid
                            })
                    except Exception as e:
                        err = e
                    if err is not None:
                        permitted_exceptions = statement.get(
                            'permitted_exceptions', [])
                        if permitted_exceptions is None:
                            permitted_exceptions = []
                        if type(err).__name__ in permitted_exceptions:
                            results.append({
                                'query': cur.query.decode("utf-8"),
                                'results': None,
                                'last_row_id': None
                            })
                        else:
                            err_msg = str(err)
                            if hasattr(err, 'message'):
                                err_msg = err.message
                            if cur.query is not None:
                                raise Exception(
                                    'Exception: {}\nStatement: {}\nError: {}'.format(type(err).__name__, cur.query.decode("utf-8"), err_msg))
                            else:
                                raise Exception(
                                    'Exception: {}\nStatement: {}\nData: {}\nError: {}'.format(type(err).__name__, statement['sql'], statement['data'], err_msg))
            if not commit_independently:
                cnx.commit()
        finally:
            cnx.close()

    else:
        raise ValueError(
            'Database type {} is not supported'.format(os.environ['DB_TYPE']))

    print(json.dumps(results))
