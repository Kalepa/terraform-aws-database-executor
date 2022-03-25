import json
import os
import sys
sys.path.insert(0, '/opt/python')

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

    dbconfig = {
        'user': os.getenv('DB_USER', None),
        'password': os.getenv('DB_PASSWORD', None),
        'host': os.getenv('DB_HOST', None),
        'port': os.getenv('DB_PORT', None),
        'database': os.getenv('DB_DATABASE', None),
    }

    statements = json.loads(os.environ['DB_STATEMENTS'])
    commit_independently = json.loads(os.environ['DB_COMMIT_INDEPENDENTLY'])
    dictionary_result = json.loads(os.environ['DB_DICTIONARY_RESULT'])

    results = []

    if os.environ['DB_TYPE'].lower() == 'mysql':
        import mysql.connector
        with mysql.connector.connect(autocommit=False, user=user, password=password, host=host, port=port, database=db_name) as cnx:
            with cnx.cursor(dictionary=dictionary_result) as cur:
                for statement in statements:
                    cur.execute(statement['sql'], statement['data'])
                    results.append(cur.fetchall())
                    if commit_independently:
                        cnx.commit()
            cnx.commit()

    elif os.environ['DB_TYPE'].lower() == 'postgresql':
        import psycopg2
        cursor_factory = None
        if dictionary_result:
            import psychopg2.extras
            cursor_factory = psychopg2.extras.RealDictCursor
        cnx = psycopg2.connect(user=user, password=password,
                               host=host, port=port, dbname=db_name)
        try:
            with cnx.cursor(cursor_factory=cursor_factory) as cur:
                for statement in statements:
                    cur.execute(statement['sql'], statement['data'])
                    results.append(cur.fetchall())
                    if commit_independently:
                        cnx.commit()
            cnx.commit()
        finally:
            cnx.close()

    else:
        raise ValueError(
            'Database type {} is not supported'.format(os.environ['DB_TYPE']))

    print(json.dumps(results))
